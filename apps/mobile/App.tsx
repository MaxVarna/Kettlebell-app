import { useEffect, useMemo, useRef, useState } from 'react';
import {
  AccessibilityInfo,
  Animated,
  AppState,
  Easing,
  Image,
  Modal,
  Pressable,
  ScrollView,
  StatusBar,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  useColorScheme,
  View,
} from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import * as Haptics from 'expo-haptics';
import { setAudioModeAsync, useAudioPlayer } from 'expo-audio';
import { useKeepAwake } from 'expo-keep-awake';
import { deleteScheme, listSchemes, markSchemeStarted, saveScheme } from './src/data/schemes';
import type { SavedScheme } from './src/data/schemes.types';
import { getAnimationEnabled, setAnimationEnabledSetting } from './src/data/settings';
import { catalogueExercises } from './src/content/exerciseCatalogue';
import type { ExerciseRecord } from './src/content/exerciseCatalogue';
import { initialRunnerState, pause, reconcile, remainingSeconds, resume, skip, start } from './src/runner/engine';
import type { Movement, RunnerPhase, RunnerScheme, RunnerState } from './src/runner/types';
import { framePlaybackOrder, nextPlaybackCursor } from './src/motion/framePlayback';

const SWING_IMAGE = require('./assets/movements/swing-top-anchored-v1.png');
const GOBLET_SQUAT_IMAGE = require('./assets/movements/goblet-squat-standing-anchored-v1.png');
const SWING_BOTTOM_IMAGE = require('./assets/movements/swing-bottom-anchored-v1.png');
const GOBLET_SQUAT_BOTTOM_IMAGE = require('./assets/movements/goblet-squat-bottom-anchored-v1.png');
const CLEAN_PRESS_LOW_IMAGE = require('./assets/movements/clean-press-low-coherent-anchored-v1.png');
const CLEAN_PRESS_RACK_IMAGE = require('./assets/movements/clean-press-rack-coherent-anchored-v1.png');
const CLEAN_PRESS_OVERHEAD_IMAGE = require('./assets/movements/clean-press-overhead-coherent-anchored-v1.png');
const START_READY_IMAGE = require('./assets/movements/start-ready-anchored-v1.png');
const REST_STANDING_IMAGE = require('./assets/movements/rest-standing-anchored-v1.png');
const SWING_ZONES_IMAGE = require('./assets/movements/swing-zones-approved-v3.png');
const GOBLET_SQUAT_ZONES_IMAGE = require('./assets/movements/goblet-squat-zones.png');
const COUNTDOWN_SOUND = require('./assets/sounds/countdown.wav');
const WORK_START_SOUND = require('./assets/sounds/work-start.wav');
const REST_START_SOUND = require('./assets/sounds/rest-start.wav');

const movementFromExercise = (exercise: ExerciseRecord): Movement => ({
  id: exercise.id,
  name: exercise.name,
  cue: exercise.cueDrafts[0] ?? exercise.keyPose,
});
const MOVEMENTS: readonly Movement[] = catalogueExercises.map(movementFromExercise);
const movementImage = (movement: Movement) => movement.id === 'goblet-squat'
  ? GOBLET_SQUAT_IMAGE
  : movement.id === 'clean-and-press' ? CLEAN_PRESS_RACK_IMAGE : SWING_IMAGE;
const movementFrames = (movement: Movement) => movement.id === 'goblet-squat'
  ? [GOBLET_SQUAT_IMAGE, GOBLET_SQUAT_BOTTOM_IMAGE]
  : movement.id === 'clean-and-press'
    ? [CLEAN_PRESS_LOW_IMAGE, CLEAN_PRESS_RACK_IMAGE, CLEAN_PRESS_OVERHEAD_IMAGE]
    : [SWING_BOTTOM_IMAGE, SWING_IMAGE];
const zoneMapImage = (exercise: ExerciseRecord) => exercise.id === 'goblet-squat'
  ? GOBLET_SQUAT_ZONES_IMAGE
  : exercise.id === 'two-hand-swing' ? SWING_ZONES_IMAGE : null;

const space = { xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32, huge: 48 } as const;
const text = { label: 12, secondary: 14, body: 16, title: 19, screen: 24, timer: 72 } as const;

const dark = {
  background: '#08121B', surface: '#0E1C28', surfaceSoft: '#132432', ink: '#F4F6F3',
  secondary: '#B2BDC5', faint: '#82909A', line: '#2B3C48', accent: '#D2A24E', accentText: '#18202A', track: '#263845',
};
const light = {
  background: '#F6F7F6', surface: '#FFFFFF', surfaceSoft: '#E9EEF0', ink: '#121A20',
  secondary: '#53626B', faint: '#63727C', line: '#D1DBDE', accent: '#BF862D', accentText: '#1A1F22', track: '#DCE4E5',
};

type Screen = 'home' | 'builder' | 'saved' | 'exercise' | 'runner' | 'summary' | 'settings';
type Draft = RunnerScheme & { id?: string; createdAt?: string };

const phaseCopy: Record<RunnerPhase, string> = { preparation: 'ПОДГОТОВКА', work: 'РАБОТА', rest: 'ОТДЫХ', completed: 'ГОТОВО' };
const phaseDuration = (scheme: RunnerScheme, phase: RunnerPhase) => phase === 'preparation'
  ? scheme.rhythm.preparationSec : phase === 'work' ? scheme.rhythm.workSec : scheme.rhythm.restSec;
const formatTime = (seconds: number) => `${Math.floor(seconds / 60).toString().padStart(2, '0')}:${(seconds % 60).toString().padStart(2, '0')}`;
const estimatedMinutes = (scheme: RunnerScheme) => Math.max(1, Math.ceil((scheme.rhythm.preparationSec + (scheme.rhythm.workSec + scheme.rhythm.restSec) * scheme.movements.length) * scheme.cycleCount / 60));
const newDraft = (): Draft => ({
  title: 'Новая схема', movements: [], rhythm: { preparationSec: 10, workSec: 30, restSec: 20 }, cycleCount: 3,
});

export default function App() {
  const systemScheme = useColorScheme();
  const colors = systemScheme === 'dark' ? dark : light;
  const styles = useMemo(() => makeStyles(colors), [colors]);
  const [screen, setScreen] = useState<Screen>('home');
  const [saved, setSaved] = useState<SavedScheme[]>([]);
  const [draft, setDraft] = useState<Draft>(newDraft);
  const [activeScheme, setActiveScheme] = useState<RunnerScheme | null>(null);
  const [completedScheme, setCompletedScheme] = useState<RunnerScheme | null>(null);
  const [selectedExercise, setSelectedExercise] = useState<ExerciseRecord | null>(null);
  const [storageError, setStorageError] = useState<string | null>(null);
  const [animationEnabled, setAnimationEnabled] = useState(true);
  const [systemReduceMotion, setSystemReduceMotion] = useState(false);

  const refreshSaved = async () => {
    try {
      setSaved(await listSchemes());
      setStorageError(null);
    } catch {
      setStorageError('Не удалось открыть локальное хранилище. Схема останется на экране, попробуйте сохранить ещё раз.');
    }
  };

  useEffect(() => {
    void refreshSaved();
    void getAnimationEnabled().then(setAnimationEnabled).catch(() => undefined);
    void AccessibilityInfo.isReduceMotionEnabled().then(setSystemReduceMotion);
    const reduceMotionSubscription = AccessibilityInfo.addEventListener('reduceMotionChanged', setSystemReduceMotion);
    return () => reduceMotionSubscription.remove();
  }, []);

  const updateAnimationEnabled = (enabled: boolean) => {
    setAnimationEnabled(enabled);
    void setAnimationEnabledSetting(enabled);
  };

  const openNew = () => { setDraft(newDraft()); setScreen('builder'); };
  const openSaved = () => { void refreshSaved(); setScreen('saved'); };
  const openExercise = (exercise: ExerciseRecord) => { setSelectedExercise(exercise); setScreen('exercise'); };
  const addSelectedExercise = () => {
    if (!selectedExercise) return;
    setDraft((current) => ({ ...current, movements: [...current.movements, movementFromExercise(selectedExercise)] }));
    setScreen('builder');
  };
  const editSaved = (scheme: SavedScheme) => { setDraft({ ...scheme, movements: [...scheme.movements] }); setScreen('builder'); };
  const removeSaved = async (scheme: SavedScheme) => {
    try {
      await deleteScheme(scheme.id);
      setSaved((items) => items.filter((item) => item.id !== scheme.id));
      setStorageError(null);
      setScreen('saved');
    } catch {
      setStorageError('Не удалось удалить схему. Попробуйте ещё раз.');
    }
  };
  const startScheme = async (scheme: RunnerScheme, savedItem?: SavedScheme) => {
    if (savedItem) {
      const updated = await markSchemeStarted(savedItem);
      setSaved((items) => [updated, ...items.filter((item) => item.id !== updated.id)]);
    }
    setActiveScheme({ ...scheme, movements: [...scheme.movements] });
    setScreen('runner');
  };
  const persistDraft = async (title: string) => {
    if (!draft.movements.length) return;
    const now = new Date().toISOString();
    const item: SavedScheme = { ...draft, title: title.trim() || 'Новая схема', id: draft.id ?? `${Date.now()}-${Math.random().toString(36).slice(2)}`, createdAt: draft.createdAt ?? now, updatedAt: now };
    try {
      await saveScheme(item);
      setDraft(item);
      setSaved((items) => [item, ...items.filter((savedItem) => savedItem.id !== item.id)]);
      setStorageError(null);
    } catch {
      setStorageError('Не удалось сохранить изменения. Повторите попытку.');
    }
  };

  if (screen === 'runner' && activeScheme) {
    return <SafeAreaProvider><Runner scheme={activeScheme} colors={colors} animationEnabled={animationEnabled && !systemReduceMotion} onExit={() => { setScreen('home'); void refreshSaved(); }} onComplete={(scheme) => { setCompletedScheme(scheme); setScreen('summary'); }} /></SafeAreaProvider>;
  }

  if (screen === 'summary' && completedScheme) {
    return <SafeAreaProvider><WorkoutSummary scheme={completedScheme} colors={colors} styles={styles} onRepeat={() => void startScheme(completedScheme)} onHome={() => { setScreen('home'); void refreshSaved(); }} /></SafeAreaProvider>;
  }

  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.safeArea} edges={['top', 'bottom']}>
        <StatusBar barStyle={systemScheme === 'dark' ? 'light-content' : 'dark-content'} />
        {screen === 'home' && (
          <Home styles={styles} saved={saved} onNew={openNew} onSaved={openSaved} onSettings={() => setScreen('settings')} onEdit={editSaved} onStart={(item) => void startScheme(item, item)} />
        )}
        {screen === 'settings' && (
          <Settings styles={styles} animationEnabled={animationEnabled} onAnimationChange={updateAnimationEnabled} onBack={() => setScreen('home')} />
        )}
        {screen === 'saved' && (
          <SavedList styles={styles} items={saved} onBack={() => setScreen('home')} onNew={openNew} onEdit={editSaved} onStart={(item) => void startScheme(item, item)} />
        )}
        {screen === 'builder' && (
          <Builder
            colors={colors} styles={styles} draft={draft} error={storageError}
            onBack={() => setScreen(draft.id ? 'saved' : 'home')} onChange={setDraft}
            onOpenExercise={openExercise}
            onSave={(title) => void persistDraft(title)}
            onDelete={draft.id ? () => void removeSaved(draft as SavedScheme) : undefined}
            onStart={() => void startScheme(draft)}
          />
        )}
        {screen === 'exercise' && selectedExercise && (
          <ExerciseDetail exercise={selectedExercise} colors={colors} styles={styles} onBack={() => setScreen('builder')} onAdd={addSelectedExercise} />
        )}
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

function Home({ styles, saved, onNew, onSaved, onSettings, onEdit, onStart }: { styles: ReturnType<typeof makeStyles>; saved: SavedScheme[]; onNew: () => void; onSaved: () => void; onSettings: () => void; onEdit: (item: SavedScheme) => void; onStart: (item: SavedScheme) => void }) {
  const recent = saved[0];
  return <ScrollView contentContainerStyle={styles.scrollContent}>
    <View style={styles.homeTitleRow}><View style={styles.homeHeader}><Text accessibilityRole="header" style={styles.screenTitle}>Тренировка</Text><Text style={styles.secondary}>Интервальный ритм с гирей</Text></View><Pressable accessibilityRole="button" style={styles.settingsButton} onPress={onSettings}><Text style={styles.settingsButtonText}>Настройки</Text></Pressable></View>
    <View style={styles.entryGroup}>
      <EntryButton title="Новая тренировка" detail="Собрать последовательность и ритм" styles={styles} onPress={onNew} />
      <EntryButton title="Сохранённые" detail={saved.length ? `${saved.length} ${saved.length === 1 ? 'схема' : 'схемы'}` : 'Ваши готовые последовательности'} styles={styles} onPress={onSaved} />
    </View>
    {recent && <View style={styles.resumeBlock}><Text style={styles.sectionLabel}>ПРОДОЛЖИТЬ</Text><SavedRow styles={styles} item={recent} onEdit={() => onEdit(recent)} onStart={() => onStart(recent)} /></View>}
  </ScrollView>;
}

function Settings({ styles, animationEnabled, onAnimationChange, onBack }: { styles: ReturnType<typeof makeStyles>; animationEnabled: boolean; onAnimationChange: (enabled: boolean) => void; onBack: () => void }) {
  return <View style={styles.page}>
    <TopBar title="Настройки" styles={styles} onBack={onBack} />
    <View style={styles.settingsContent}>
      <View style={styles.settingsRow}>
        <View style={styles.settingsCopy}><Text style={styles.settingsTitle}>Анимация движения</Text><Text style={styles.settingsDescription}>{animationEnabled ? 'Фазы сменяются плавным затуханием' : 'Все ключевые позы показаны статично'}</Text></View>
        <Switch accessibilityLabel="Анимация движения" value={animationEnabled} onValueChange={onAnimationChange} />
      </View>
    </View>
  </View>;
}

function EntryButton({ title, detail, styles, onPress }: { title: string; detail: string; styles: ReturnType<typeof makeStyles>; onPress: () => void }) {
  return <Pressable accessibilityRole="button" style={({ pressed }) => [styles.entryButton, pressed && styles.pressed]} onPress={onPress}>
    <View><Text style={styles.entryTitle}>{title}</Text><Text style={styles.entryDetail}>{detail}</Text></View><Text style={styles.entryArrow}>→</Text>
  </Pressable>;
}

function SavedList({ styles, items, onBack, onNew, onEdit, onStart }: { styles: ReturnType<typeof makeStyles>; items: SavedScheme[]; onBack: () => void; onNew: () => void; onEdit: (item: SavedScheme) => void; onStart: (item: SavedScheme) => void }) {
  return <View style={styles.page}><TopBar title="Сохранённые" styles={styles} onBack={onBack} />
    {items.length ? <ScrollView contentContainerStyle={styles.listContent}>{items.map((item) => <SavedRow key={item.id} styles={styles} item={item} onEdit={() => onEdit(item)} onStart={() => onStart(item)} />)}</ScrollView> :
      <View style={styles.empty}><Text style={styles.emptyTitle}>Здесь появятся ваши схемы</Text><Text style={styles.emptyText}>Сохраните последовательность, чтобы запускать её без повторной настройки.</Text><Pressable style={styles.primaryButton} onPress={onNew}><Text style={styles.primaryButtonText}>Создать первую</Text></Pressable></View>}
  </View>;
}

function SavedRow({ styles, item, onEdit, onStart }: { styles: ReturnType<typeof makeStyles>; item: SavedScheme; onEdit: () => void; onStart: () => void }) {
  const movement = item.movements[0] ?? MOVEMENTS[0]!;
  return <View style={styles.savedRow}>
    <Pressable accessibilityRole="button" accessibilityLabel={`Открыть схему ${item.title}`} style={({ pressed }) => [{ flex: 1, minHeight: 78, flexDirection: 'row', alignItems: 'center', gap: space.md }, pressed && styles.pressed]} onPress={onEdit}><Image source={movementImage(movement)} resizeMode="contain" style={styles.thumb} accessibilityLabel={`Миниатюра: ${movement.name}`} /><View style={styles.savedText}><Text numberOfLines={1} style={styles.savedTitle}>{item.title}</Text><Text numberOfLines={1} style={styles.savedMeta}>{estimatedMinutes(item)} мин · {item.movements.length} движ. · {item.cycleCount} цикл.</Text></View></Pressable>
    <Pressable accessibilityRole="button" hitSlop={8} style={({ pressed }) => [styles.startSmall, pressed && styles.pressed]} onPress={onStart}><Text style={styles.startSmallText}>Старт</Text></Pressable>
  </View>;
}

function Builder({ colors, styles, draft, error, onBack, onChange, onOpenExercise, onSave, onDelete, onStart }: { colors: typeof dark; styles: ReturnType<typeof makeStyles>; draft: Draft; error: string | null; onBack: () => void; onChange: (draft: Draft) => void; onOpenExercise: (exercise: ExerciseRecord) => void; onSave: (title: string) => void; onDelete?: () => void; onStart: () => void }) {
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [saveNameOpen, setSaveNameOpen] = useState(false);
  const [saveName, setSaveName] = useState(draft.title);
  const saveNameStyles = useMemo(() => makeSaveNameStyles(colors), [colors]);
  const removeMovement = (index: number) => onChange({ ...draft, movements: draft.movements.filter((_, itemIndex) => itemIndex !== index) });
  const moveMovement = (index: number, direction: -1 | 1) => {
    const targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= draft.movements.length) return;
    const movements = [...draft.movements];
    [movements[index], movements[targetIndex]] = [movements[targetIndex]!, movements[index]!];
    onChange({ ...draft, movements });
  };
  const adjust = (key: keyof Draft['rhythm'], delta: number) => onChange({ ...draft, rhythm: { ...draft.rhythm, [key]: Math.max(5, draft.rhythm[key] + delta) } });
  const valid = draft.movements.length > 0;
  const openSaveName = () => { setSaveName(draft.title); setSaveNameOpen(true); };
  const confirmSave = () => { onSave(saveName); setSaveNameOpen(false); };
  return <View style={styles.page}><TopBar title={draft.id ? 'Схема' : 'Новая тренировка'} styles={styles} onBack={onBack} />
    <ScrollView contentContainerStyle={styles.builderContent} keyboardShouldPersistTaps="handled">
      <Section title="Ритм цикла" styles={styles}><View style={styles.rhythm}>{([
        ['preparationSec', 'Подготовка'], ['workSec', 'Работа'], ['restSec', 'Отдых'],
      ] as const).map(([key, label]) => <Stepper key={key} label={label} seconds={draft.rhythm[key]} styles={styles} onMinus={() => adjust(key, -5)} onPlus={() => adjust(key, 5)} />)}</View></Section>
      <Section title="Последовательность" styles={styles}>
        {draft.movements.length === 0 ? <Text style={styles.helper}>Добавьте первое движение.</Text> : draft.movements.map((movement, index) => <View key={`${movement.id}-${index}`} style={styles.movementRow}><Text style={styles.order}>{index + 1}</Text><Image source={movementImage(movement)} resizeMode="contain" style={styles.rowThumb} /><Text style={styles.movementRowTitle}>{movement.name}</Text><View style={styles.movementActions}><Pressable accessibilityRole="button" accessibilityLabel={`Поднять ${movement.name}`} disabled={index === 0} style={({ pressed }) => [styles.orderAction, index === 0 && styles.orderActionDisabled, pressed && styles.pressed]} onPress={() => moveMovement(index, -1)}><Text style={styles.orderActionText}>↑</Text></Pressable><Pressable accessibilityRole="button" accessibilityLabel={`Опустить ${movement.name}`} disabled={index === draft.movements.length - 1} style={({ pressed }) => [styles.orderAction, index === draft.movements.length - 1 && styles.orderActionDisabled, pressed && styles.pressed]} onPress={() => moveMovement(index, 1)}><Text style={styles.orderActionText}>↓</Text></Pressable><Pressable accessibilityRole="button" accessibilityLabel={`Убрать ${movement.name}`} style={({ pressed }) => [styles.removeMovement, pressed && styles.pressed]} onPress={() => removeMovement(index)}><Text style={styles.removeMovementText}>Убрать</Text></Pressable></View></View>)}
        <Text style={styles.catalogueLabel}>Добавить движение</Text>
        <View style={styles.catalogueGrid}>{catalogueExercises.map((exercise) => <Pressable key={exercise.id} accessibilityRole="button" accessibilityLabel={`Открыть упражнение ${exercise.name}`} style={({ pressed }) => [styles.addMovementGrid, pressed && styles.pressed]} onPress={() => onOpenExercise(exercise)}><Image source={movementImage(movementFromExercise(exercise))} resizeMode="contain" style={styles.addMovementThumb} /><Text numberOfLines={1} adjustsFontSizeToFit minimumFontScale={0.86} style={styles.addMovementText}>{exercise.name}</Text><Text style={styles.addMovementPlus}>+</Text></Pressable>)}</View>
      </Section>
      <Section title="Циклы" styles={styles}><View style={styles.cyclesLine}><Text style={styles.helper}>Повторить всю последовательность</Text><View style={styles.cycleStepper}><Pressable style={styles.stepButton} onPress={() => onChange({ ...draft, cycleCount: Math.max(1, draft.cycleCount - 1) })}><Text style={styles.stepSymbol}>−</Text></Pressable><Text style={styles.cycleValue}>{draft.cycleCount}</Text><Pressable style={styles.stepButton} onPress={() => onChange({ ...draft, cycleCount: draft.cycleCount + 1 })}><Text style={styles.stepSymbol}>+</Text></Pressable></View></View></Section>
      {error && <Text accessibilityLiveRegion="polite" style={styles.error}>{error}</Text>}
      {valid && <Text style={styles.duration}>{estimatedMinutes(draft)} мин · {draft.movements.length} движ. · {draft.cycleCount} цикл.</Text>}
      {onDelete && (confirmDelete ? <View style={{ marginTop: space.xl, gap: space.md }}><Text style={styles.helper}>Удалить схему без возможности восстановления?</Text><View style={{ flexDirection: 'row', gap: space.md }}><Pressable accessibilityRole="button" style={styles.stopButton} onPress={() => setConfirmDelete(false)}><Text style={styles.stopButtonText}>Отмена</Text></Pressable><Pressable accessibilityRole="button" style={{ minHeight: 56, flex: 1, justifyContent: 'center', alignItems: 'center', borderRadius: 14, backgroundColor: '#B73434' }} onPress={onDelete}><Text style={{ color: '#FFFFFF', fontSize: text.secondary, fontWeight: '700' }}>Подтвердить удаление</Text></Pressable></View></View> : <Pressable accessibilityRole="button" style={{ alignSelf: 'flex-start', minHeight: 44, justifyContent: 'center', marginTop: space.lg }} onPress={() => setConfirmDelete(true)}><Text style={{ color: '#B73434', fontSize: text.secondary, fontWeight: '700' }}>Удалить схему</Text></Pressable>)}
    </ScrollView>
    <Modal transparent animationType="fade" visible={saveNameOpen} onRequestClose={() => setSaveNameOpen(false)}>
      <View style={saveNameStyles.backdrop}>
        <View style={saveNameStyles.sheet}>
          <Text accessibilityRole="header" style={saveNameStyles.title}>Сохранить схему</Text>
          <Text style={saveNameStyles.description}>Как она будет называться в списке сохранённых?</Text>
          <TextInput accessibilityLabel="Название сохраняемой схемы" autoFocus value={saveName} onChangeText={setSaveName} style={saveNameStyles.input} placeholder="Например, утренняя связка" placeholderTextColor={colors.faint} />
          <View style={saveNameStyles.actions}>
            <Pressable accessibilityRole="button" style={saveNameStyles.cancel} onPress={() => setSaveNameOpen(false)}><Text style={saveNameStyles.cancelText}>Отмена</Text></Pressable>
            <Pressable accessibilityRole="button" style={saveNameStyles.confirm} onPress={confirmSave}><Text style={saveNameStyles.confirmText}>Сохранить</Text></Pressable>
          </View>
        </View>
      </View>
    </Modal>
    <View style={styles.actionBar}><Pressable accessibilityRole="button" disabled={!valid} style={({ pressed }) => [styles.saveButton, !valid && styles.disabled, pressed && styles.pressed]} onPress={openSaveName}><Text style={styles.saveButtonText}>Сохранить</Text></Pressable><Pressable accessibilityRole="button" disabled={!valid} style={({ pressed }) => [styles.primaryButton, !valid && styles.disabled, pressed && styles.pressed]} onPress={onStart}><Text style={styles.primaryButtonText}>Начать</Text></Pressable></View>
  </View>;
}

function ExerciseDetail({ exercise, colors, styles, onBack, onAdd }: { exercise: ExerciseRecord; colors: typeof dark; styles: ReturnType<typeof makeStyles>; onBack: () => void; onAdd: () => void }) {
  const detailStyles = useMemo(() => makeExerciseDetailStyles(colors), [colors]);
  const movement = movementFromExercise(exercise);
  const frames = movementFrames(movement);
  const zonesImage = zoneMapImage(exercise);
  return <View style={styles.page}>
    <TopBar title={exercise.name} styles={styles} onBack={onBack} />
    <ScrollView contentContainerStyle={detailStyles.content} showsVerticalScrollIndicator={false}>
      <View style={detailStyles.hero}>
        <View style={detailStyles.phaseSequence}>{frames.map((frame, index) => <View key={`${movement.id}-phase-${index}`} style={detailStyles.phaseGroup}><View style={detailStyles.phaseFrame}><Image source={frame} resizeMode="contain" style={detailStyles.exerciseVisual} accessibilityLabel={`Фаза ${index + 1} упражнения ${exercise.name}`} /></View><Text style={detailStyles.phaseNumber}>{index + 1}</Text></View>)}</View>
      </View>
      {zonesImage && <><View style={detailStyles.divider} />
      <View style={detailStyles.zones}>
        <Text style={detailStyles.sectionTitle}>Задействованные зоны</Text>
        <Image source={zonesImage} resizeMode="contain" style={[detailStyles.zoneVisual, { opacity: 0.99 }]} accessibilityLabel={`Зоны: ${exercise.zoneMap.join(', ')}`} />
      </View></>}
      <View style={detailStyles.divider} />
      <View style={detailStyles.referenceRow} accessibilityLabel="Справочная схема">
        <Text style={detailStyles.referenceIcon}>ⓘ</Text><Text style={detailStyles.referenceText}>Справочная схема</Text><Text style={detailStyles.referenceArrow}>›</Text>
      </View>
    </ScrollView>
    <View style={detailStyles.footer}><Pressable accessibilityRole="button" style={({ pressed }) => [detailStyles.addButton, pressed && styles.pressed]} onPress={onAdd}><Text style={detailStyles.addButtonText}>Добавить в схему</Text></Pressable></View>
  </View>;
}

function Section({ title, styles, children }: { title: string; styles: ReturnType<typeof makeStyles>; children: React.ReactNode }) { return <View style={styles.section}><Text style={styles.sectionTitle}>{title}</Text>{children}</View>; }
function Stepper({ label, seconds, styles, onMinus, onPlus }: { label: string; seconds: number; styles: ReturnType<typeof makeStyles>; onMinus: () => void; onPlus: () => void }) { return <View style={styles.stepper}><Text style={styles.stepperLabel}>{label}</Text><View style={styles.stepperValue}><Pressable accessibilityRole="button" style={styles.stepButton} onPress={onPlus}><Text style={styles.stepSymbol}>+</Text></Pressable><Text style={styles.seconds}>{seconds}с</Text><Pressable accessibilityRole="button" style={styles.stepButton} onPress={onMinus}><Text style={styles.stepSymbol}>−</Text></Pressable></View></View>; }
function TopBar({ title, styles, onBack }: { title: string; styles: ReturnType<typeof makeStyles>; onBack: () => void }) { return <View style={styles.topBar}><Pressable accessibilityRole="button" style={styles.back} onPress={onBack}><Text style={styles.backText}>‹</Text></Pressable><Text accessibilityRole="header" style={styles.screenTitle}>{title}</Text><View style={styles.back} /></View>; }

function nextRunnerStep(scheme: RunnerScheme, state: RunnerState, movement: Movement, complete: boolean) {
  if (complete) return 'Сессия завершена';
  if (state.phase === 'work') return 'Отдых';
  if (state.phase === 'rest') {
    const nextMovement = scheme.movements[state.movementIndex + 1];
    if (nextMovement) return nextMovement.name;
    return state.cycleIndex + 1 === scheme.cycleCount ? 'Завершение' : scheme.movements[0]?.name ?? movement.name;
  }
  return movement.name;
}

const phaseVisual = (colors: typeof dark, phase: RunnerPhase) => {
  const darkMode = colors === dark;
  const values = darkMode
    ? { preparation: ['#8FA8B8', 'rgba(143,168,184,0.20)'], work: ['#D2A24E', 'rgba(226,122,28,0.30)'], rest: ['#70A896', 'rgba(112,168,150,0.20)'] }
    : { preparation: ['#638398', 'rgba(99,131,152,0.18)'], work: ['#BF862D', 'rgba(221,112,20,0.25)'], rest: ['#4F937E', 'rgba(79,147,126,0.18)'] };
  const [color, fill] = values[phase === 'completed' ? 'preparation' : phase];
  return { color, fill };
};

function WorkoutSummary({ scheme, colors, styles, onRepeat, onHome }: { scheme: RunnerScheme; colors: typeof dark; styles: ReturnType<typeof makeStyles>; onRepeat: () => void; onHome: () => void }) {
  return <SafeAreaView style={styles.safeArea}><StatusBar barStyle={colors === dark ? 'light-content' : 'dark-content'} /><View style={styles.page}>
    <ScrollView contentContainerStyle={styles.scrollContent}><View style={styles.homeHeader}><Text accessibilityRole="header" style={styles.screenTitle}>Тренировка завершена</Text><Text style={styles.secondary}>{estimatedMinutes(scheme)} мин · {scheme.cycleCount} цикл.</Text></View>
      <View style={[styles.section, { marginTop: space.huge }]}><Text style={styles.sectionTitle}>Последовательность</Text>{scheme.movements.map((movement, index) => <View key={`${movement.id}-${index}`} style={styles.savedRow}><Text style={styles.order}>{index + 1}</Text><Image source={movementImage(movement)} resizeMode="contain" style={styles.thumb} /><Text style={styles.movementRowTitle}>{movement.name}</Text></View>)}</View>
    </ScrollView><View style={styles.actionBar}><Pressable style={styles.saveButton} onPress={onHome}><Text style={styles.saveButtonText}>На главную</Text></Pressable><Pressable style={styles.primaryButton} onPress={onRepeat}><Text style={styles.primaryButtonText}>Повторить</Text></Pressable></View>
  </View></SafeAreaView>;
}

function Runner({ scheme, colors, animationEnabled, onExit, onComplete }: { scheme: RunnerScheme; colors: typeof dark; animationEnabled: boolean; onExit: () => void; onComplete: (scheme: RunnerScheme) => void }) {
  const styles = useMemo(() => makeStyles(colors), [colors]);
  const [state, setState] = useState<RunnerState>(initialRunnerState);
  const [started, setStarted] = useState(false);
  const [now, setNow] = useState(Date.now());
  const [confirmStop, setConfirmStop] = useState(false);
  const [resumeAfterStopCancel, setResumeAfterStopCancel] = useState(false);
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [skipConfirm, setSkipConfirm] = useState(false);
  const [appActive, setAppActive] = useState(AppState.currentState === 'active');
  const [visibleFrameIndex, setVisibleFrameIndex] = useState(0);
  const frameOpacity = useRef(new Animated.Value(1)).current;
  const phaseKey = `${state.phase}-${state.cycleIndex}-${state.movementIndex}`;
  const previousPhase = useRef(phaseKey);
  const lastCountdown = useRef('');
  const completionNotified = useRef(false);
  const countdownPlayer = useAudioPlayer(COUNTDOWN_SOUND, { keepAudioSessionActive: true });
  const workPlayer = useAudioPlayer(WORK_START_SOUND, { keepAudioSessionActive: true });
  const restPlayer = useAudioPlayer(REST_START_SOUND, { keepAudioSessionActive: true });
  useKeepAwake('kettlebell-runner', { suppressDeactivateWarnings: true });
  useEffect(() => { void setAudioModeAsync({ playsInSilentMode: true }); }, []);
  useEffect(() => { if (!started || state.phaseEndsAtMs === null) return; const id = setInterval(() => { const current = Date.now(); setNow(current); setState((item) => reconcile(scheme, item, current)); }, 250); return () => clearInterval(id); }, [scheme, started, state.phaseEndsAtMs]);
  useEffect(() => { const subscription = AppState.addEventListener('change', (status) => { const active = status === 'active'; setAppActive(active); if (!active || !started) return; const current = Date.now(); setNow(current); setState((item) => reconcile(scheme, item, current)); }); return () => subscription.remove(); }, [started, scheme]);
  useEffect(() => { if (!started || previousPhase.current === phaseKey) return; previousPhase.current = phaseKey; void Haptics.impactAsync(state.phase === 'work' ? Haptics.ImpactFeedbackStyle.Medium : Haptics.ImpactFeedbackStyle.Light); if (soundEnabled && state.phase === 'work') { workPlayer.seekTo(0); workPlayer.play(); } if (soundEnabled && state.phase === 'rest') { restPlayer.seekTo(0); restPlayer.play(); } }, [phaseKey, soundEnabled, started, state.phase, workPlayer, restPlayer]);
  const paused = state.pausedRemainingMs !== null;
  const complete = state.phase === 'completed';
  const movement = scheme.movements[state.movementIndex] ?? MOVEMENTS[0]!;
  const seconds = started ? remainingSeconds(state, now) : scheme.rhythm.preparationSec;
  const phase = !started ? 'ГОТОВО' : paused ? 'ПАУЗА' : phaseCopy[state.phase];
  const visual = phaseVisual(colors, state.phase);
  const motionTitle = !started ? 'Начинай!' : state.phase === 'work' ? movement.name : null;
  const frames = movementFrames(movement);
  const playbackOrder = useMemo(() => framePlaybackOrder(frames.length), [frames.length, movement.id]);
  const nextStep = nextRunnerStep(scheme, state, movement, complete);
  const begin = () => { const current = Date.now(); previousPhase.current = 'initial'; setNow(current); setState(start(scheme, current)); setStarted(true); };
  const toggle = () => { const current = Date.now(); setNow(current); setState((item) => paused ? resume(item, current) : pause(item, current)); };
  useEffect(() => { if (!soundEnabled || !started || paused || complete || ![3, 2, 1].includes(seconds)) return; const key = `${phaseKey}-${seconds}`; if (lastCountdown.current === key) return; lastCountdown.current = key; countdownPlayer.seekTo(0); countdownPlayer.play(); }, [complete, countdownPlayer, paused, phaseKey, seconds, soundEnabled, started]);
  useEffect(() => { if (!complete || completionNotified.current) return; completionNotified.current = true; onComplete(scheme); }, [complete, onComplete, scheme]);
  useEffect(() => { if (!skipConfirm) return; const id = setTimeout(() => setSkipConfirm(false), 2500); return () => clearTimeout(id); }, [skipConfirm]);
  useEffect(() => {
    let cancelled = false;
    let holdTimer: ReturnType<typeof setTimeout> | undefined;
    let renderFrame: number | undefined;

    frameOpacity.stopAnimation();
    frameOpacity.setValue(1);

    if (!animationEnabled || !started || complete || state.phase !== 'work') {
      setVisibleFrameIndex(0);
      return () => { cancelled = true; };
    }

    if (paused || !appActive) {
      return () => { cancelled = true; };
    }

    let cursor = 0;
    setVisibleFrameIndex(playbackOrder[0] ?? 0);

    const scheduleNext = () => {
      holdTimer = setTimeout(() => {
        if (cancelled) return;
        Animated.timing(frameOpacity, {
          toValue: 0,
          duration: 180,
          easing: Easing.out(Easing.quad),
          useNativeDriver: true,
        }).start(({ finished }) => {
          if (!finished || cancelled) return;
          cursor = nextPlaybackCursor(playbackOrder, cursor);
          setVisibleFrameIndex(playbackOrder[cursor] ?? 0);
          renderFrame = requestAnimationFrame(() => {
            if (cancelled) return;
            Animated.timing(frameOpacity, {
              toValue: 1,
              duration: 220,
              easing: Easing.out(Easing.quad),
              useNativeDriver: true,
            }).start(({ finished: revealed }) => {
              if (revealed && !cancelled) scheduleNext();
            });
          });
        });
      }, 760);
    };

    scheduleNext();
    return () => {
      cancelled = true;
      if (holdTimer) clearTimeout(holdTimer);
      if (renderFrame !== undefined) cancelAnimationFrame(renderFrame);
      frameOpacity.stopAnimation();
    };
  }, [animationEnabled, appActive, complete, frameOpacity, movement.id, paused, playbackOrder, started, state.phase]);
  const openStopConfirmation = () => {
    const current = Date.now();
    const wasRunning = state.pausedRemainingMs === null;
    setNow(current);
    setResumeAfterStopCancel(wasRunning);
    if (wasRunning) setState((item) => pause(item, current));
    setConfirmStop(true);
  };
  const cancelStopConfirmation = () => {
    const current = Date.now();
    setNow(current);
    if (resumeAfterStopCancel) setState((item) => resume(item, current));
    setConfirmStop(false);
  };
  const requestSkip = () => { if (!skipConfirm) { setSkipConfirm(true); return; } const current = Date.now(); setNow(current); setState((item) => skip(scheme, item, current)); setSkipConfirm(false); };

  return <SafeAreaView style={styles.safeArea}><StatusBar barStyle={colors === dark ? 'light-content' : 'dark-content'} /><View style={styles.runnerScreen}>
    <View style={styles.runnerTop}><Text numberOfLines={1} style={[styles.runnerTitle, { flex: 1 }]}>{scheme.title}</Text><View style={{ flexDirection: 'row', alignItems: 'center', gap: space.sm }}><Text style={styles.cycle}>ЦИКЛ {Math.min(state.cycleIndex + 1, scheme.cycleCount)} / {scheme.cycleCount}</Text><Pressable accessibilityRole="switch" accessibilityState={{ checked: soundEnabled }} onPress={() => setSoundEnabled((value) => !value)} style={{ minHeight: 44, justifyContent: 'center' }}><Text style={[styles.cycle, { color: soundEnabled ? visual.color : colors.faint }]}>{soundEnabled ? 'ЗВУК' : 'БЕЗ ЗВУКА'}</Text></Pressable></View></View>
    {animationEnabled ? <>
      <View style={styles.runnerMotion}><View style={[styles.motionHalo, { width: 196, height: 196, borderRadius: 98, borderColor: visual.color, backgroundColor: visual.fill }]} />{!started || state.phase === 'preparation' ? <Image source={START_READY_IMAGE} resizeMode="contain" style={styles.runnerSingleFigure} accessibilityLabel="Энергичная стойка готовности" /> : state.phase === 'rest' ? <Image source={REST_STANDING_IMAGE} resizeMode="contain" style={styles.runnerSingleFigure} accessibilityLabel="Стоячая поза отдыха" /> : <View style={styles.runnerFigureStage}><Animated.Image source={frames[visibleFrameIndex] ?? frames[0]} resizeMode="contain" style={[styles.runnerFigureFrame, { opacity: frameOpacity }]} accessibilityLabel={`Фаза ${visibleFrameIndex + 1} движения ${movement.name}`} /></View>}{motionTitle && <Text numberOfLines={2} adjustsFontSizeToFit minimumFontScale={0.82} style={[styles.runnerMovement, !started && styles.runnerStartPrompt]}>{motionTitle}</Text>}</View>
      {started && <View style={styles.timerBlock}><Text style={[styles.phaseLabel, { color: visual.color }]}>{phase}</Text><Text accessibilityLiveRegion="polite" style={styles.timer}>{formatTime(seconds)}</Text><View style={styles.progressLine}><View style={[styles.progressFill, { width: `${Math.max(4, Math.min(100, ((phaseDuration(scheme, state.phase) - seconds) / phaseDuration(scheme, state.phase)) * 100))}%`, backgroundColor: visual.color }]} /></View></View>}
    </> : <View style={styles.minimalRunner}>
      {motionTitle && <Text numberOfLines={2} adjustsFontSizeToFit minimumFontScale={0.72} style={[styles.minimalMovement, !started && styles.minimalStartPrompt]}>{motionTitle}</Text>}
      {started && <View style={styles.minimalTimerBlock}><Text style={[styles.minimalPhaseLabel, { color: visual.color }]}>{phase}</Text><Text accessibilityLiveRegion="polite" style={styles.minimalTimer}>{formatTime(seconds)}</Text><View style={styles.progressLine}><View style={[styles.progressFill, { width: `${Math.max(4, Math.min(100, ((phaseDuration(scheme, state.phase) - seconds) / phaseDuration(scheme, state.phase)) * 100))}%`, backgroundColor: visual.color }]} /></View></View>}
    </View>}
    <View style={styles.nextRow}><Text style={styles.sectionLabel}>ДАЛЬШЕ</Text><Text style={styles.nextText}>{nextStep}</Text></View>
    <View style={styles.controls}>{!started ? <Pressable style={styles.primaryButton} onPress={begin}><Text style={styles.primaryButtonText}>Начать</Text></Pressable> : confirmStop ? <><Pressable style={styles.primaryButton} onPress={onExit}><Text style={styles.primaryButtonText}>Подтвердить завершение</Text></Pressable><Pressable style={styles.stopButton} onPress={cancelStopConfirmation}><Text style={styles.stopButtonText}>Продолжить</Text></Pressable></> : <><Pressable style={styles.primaryButton} onPress={toggle}><Text style={styles.primaryButtonText}>{paused ? 'Продолжить' : 'Пауза'}</Text></Pressable><Pressable style={[styles.stopButton, skipConfirm && { backgroundColor: colors.accent }]} onPress={requestSkip}><Text style={[styles.stopButtonText, skipConfirm && { color: colors.accentText }]}>{skipConfirm ? 'Точно?' : 'Пропустить'}</Text></Pressable><Pressable style={styles.stopButton} onPress={openStopConfirmation}><Text style={styles.stopButtonText}>Завершить</Text></Pressable></>}</View>
  </View></SafeAreaView>;
}

const makeStyles = (colors: typeof dark) => StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: colors.background }, page: { flex: 1, backgroundColor: colors.background }, scrollContent: { padding: space.xl, paddingTop: space.xxl, flexGrow: 1 }, homeHeader: { gap: space.sm }, screenTitle: { color: colors.ink, fontSize: text.screen, lineHeight: 30, fontWeight: '700', letterSpacing: -0.35 }, secondary: { color: colors.secondary, fontSize: text.body, lineHeight: 23 }, entryGroup: { gap: space.lg, marginTop: space.huge }, entryButton: { minHeight: 104, padding: space.xl, backgroundColor: colors.surface, borderRadius: 16, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }, entryTitle: { color: colors.ink, fontSize: text.title, lineHeight: 24, fontWeight: '700' }, entryDetail: { color: colors.secondary, fontSize: text.secondary, lineHeight: 20, marginTop: space.xs }, entryArrow: { color: colors.accent, fontSize: 26, fontWeight: '400' }, resumeBlock: { marginTop: space.huge }, sectionLabel: { color: colors.faint, fontSize: text.label, fontWeight: '700', letterSpacing: 1.1 }, listContent: { paddingHorizontal: space.xl, paddingBottom: space.xxl }, topBar: { paddingHorizontal: space.xl, paddingTop: space.sm, paddingBottom: space.lg, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }, back: { width: 48, height: 48, justifyContent: 'center' }, backText: { color: colors.ink, fontSize: 36, lineHeight: 38, fontWeight: '300' }, empty: { flex: 1, padding: space.xxl, justifyContent: 'center', gap: space.md }, emptyTitle: { color: colors.ink, fontSize: text.title, lineHeight: 25, fontWeight: '700' }, emptyText: { color: colors.secondary, fontSize: text.body, lineHeight: 23, marginBottom: space.lg }, savedRow: { minHeight: 98, paddingVertical: space.md, flexDirection: 'row', alignItems: 'center', gap: space.md, borderBottomWidth: StyleSheet.hairlineWidth, borderColor: colors.line }, thumb: { width: 60, height: 78 }, savedText: { flex: 1, gap: space.xs }, savedTitle: { color: colors.ink, fontSize: text.body, lineHeight: 21, fontWeight: '700' }, savedMeta: { color: colors.secondary, fontSize: text.secondary, lineHeight: 19 }, startSmall: { minHeight: 48, minWidth: 56, justifyContent: 'center', alignItems: 'center' }, startSmallText: { color: colors.accent, fontSize: text.secondary, fontWeight: '700' }, builderContent: { paddingHorizontal: space.xl, paddingBottom: 112 }, nameInput: { color: colors.ink, fontSize: text.title, lineHeight: 25, fontWeight: '700', paddingVertical: space.lg, borderBottomWidth: StyleSheet.hairlineWidth, borderColor: colors.line }, placeholder: { color: colors.faint }, section: { marginTop: space.xxl, gap: space.md }, sectionTitle: { color: colors.ink, fontSize: text.title, lineHeight: 25, fontWeight: '700' }, helper: { color: colors.secondary, fontSize: text.secondary, lineHeight: 20 }, rhythm: { flexDirection: 'row', gap: space.sm }, stepper: { flex: 1, gap: space.sm }, stepperLabel: { color: colors.secondary, fontSize: text.label, lineHeight: 16 }, stepperValue: { alignItems: 'center', backgroundColor: colors.surface, borderRadius: 12, paddingVertical: space.sm, gap: space.xs }, stepButton: { minHeight: 44, minWidth: 44, justifyContent: 'center', alignItems: 'center' }, stepSymbol: { color: colors.ink, fontSize: 22, fontWeight: '400' }, seconds: { color: colors.ink, fontSize: text.title, fontWeight: '700', fontVariant: ['tabular-nums'] }, movementRow: { minHeight: 64, flexDirection: 'row', alignItems: 'center', gap: space.sm, borderBottomWidth: StyleSheet.hairlineWidth, borderColor: colors.line }, order: { color: colors.faint, fontSize: text.label, width: 16, fontWeight: '700' }, rowThumb: { width: 42, height: 52 }, movementRowTitle: { color: colors.ink, fontSize: text.body, fontWeight: '600', flex: 1 }, movementActions: { flexDirection: 'row', alignItems: 'center' }, orderAction: { width: 44, minHeight: 44, justifyContent: 'center', alignItems: 'center' }, orderActionDisabled: { opacity: 0.2 }, orderActionText: { color: colors.secondary, fontSize: 18, lineHeight: 22, fontWeight: '600' }, removeMovement: { minHeight: 44, justifyContent: 'center', paddingHorizontal: space.xs }, removeMovementText: { color: colors.secondary, fontSize: text.label, fontWeight: '700' }, catalogueLabel: { color: colors.secondary, fontSize: text.secondary, lineHeight: 20, marginTop: space.md }, catalogueChoices: { flexDirection: 'row', gap: space.sm }, addMovement: { minHeight: 136, flex: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: space.sm, paddingVertical: space.md, borderRadius: 12, backgroundColor: colors.surfaceSoft, position: 'relative' }, addMovementThumb: { height: 82, width: 86 }, addMovementText: { alignSelf: 'stretch', color: colors.ink, fontSize: text.secondary, lineHeight: 20, fontWeight: '700', textAlign: 'center', paddingHorizontal: space.xs }, addMovementPlus: { color: colors.accent, fontSize: 22, lineHeight: 24, fontWeight: '400', position: 'absolute', top: space.sm, right: space.sm }, cyclesLine: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: space.md }, cycleStepper: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.surface, borderRadius: 12 }, cycleValue: { color: colors.ink, minWidth: 26, textAlign: 'center', fontSize: text.title, fontWeight: '700', fontVariant: ['tabular-nums'] }, error: { marginTop: space.xl, color: '#C53C3C', fontSize: text.secondary, lineHeight: 20 }, duration: { color: colors.secondary, fontSize: text.secondary, lineHeight: 20, marginTop: space.xxl }, actionBar: { paddingHorizontal: space.xl, paddingTop: space.md, paddingBottom: space.lg, flexDirection: 'row', gap: space.md, backgroundColor: colors.background, borderTopWidth: StyleSheet.hairlineWidth, borderColor: colors.line }, primaryButton: { minHeight: 56, flex: 1, justifyContent: 'center', alignItems: 'center', borderRadius: 14, backgroundColor: colors.accent }, primaryButtonText: { color: colors.accentText, fontSize: text.body, fontWeight: '700' }, saveButton: { minHeight: 56, paddingHorizontal: space.lg, justifyContent: 'center', alignItems: 'center', borderRadius: 14, backgroundColor: colors.surfaceSoft }, saveButtonText: { color: colors.ink, fontSize: text.body, fontWeight: '700' }, disabled: { opacity: 0.42 }, pressed: { opacity: 0.78, transform: [{ scale: 0.99 }] }, runnerScreen: { flex: 1, backgroundColor: colors.background, paddingHorizontal: space.xl, paddingBottom: space.lg }, runnerTop: { paddingTop: space.sm, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'baseline' }, runnerTitle: { color: colors.ink, fontSize: text.title, fontWeight: '600' }, cycle: { color: colors.secondary, fontSize: text.label, fontWeight: '700', letterSpacing: 0.75 }, runnerMotion: { flex: 1, minHeight: 250, justifyContent: 'center', alignItems: 'center' }, motionHalo: { position: 'absolute', height: 230, width: 230, borderRadius: 115, borderWidth: 1, borderColor: colors.line }, runnerFigure: { width: '56%', height: '80%' }, runnerMovement: { color: colors.ink, fontSize: 30, lineHeight: 36, fontWeight: '700', textAlign: 'center', paddingHorizontal: space.xl }, motionHint: { color: colors.secondary, fontSize: text.secondary, lineHeight: 20, marginTop: space.xs }, timerBlock: { paddingVertical: space.xl, borderTopWidth: StyleSheet.hairlineWidth, borderBottomWidth: StyleSheet.hairlineWidth, borderColor: colors.line, alignItems: 'center' }, phaseLabel: { color: colors.secondary, fontSize: 22, lineHeight: 28, fontWeight: '700', letterSpacing: 1.5 }, timer: { color: colors.ink, fontSize: text.timer, lineHeight: 84, fontWeight: '300', letterSpacing: -2.4, fontVariant: ['tabular-nums'] }, progressLine: { width: '100%', height: 2, marginTop: space.sm, backgroundColor: colors.track }, progressFill: { height: 2 }, nextRow: { paddingVertical: space.xl, gap: space.sm }, nextText: { color: colors.secondary, fontSize: text.body, lineHeight: 23 }, controls: { flexDirection: 'row', gap: space.md }, stopButton: { minHeight: 56, paddingHorizontal: space.lg, justifyContent: 'center', alignItems: 'center', borderRadius: 14, backgroundColor: colors.surfaceSoft }, stopButtonText: { color: colors.ink, fontSize: text.secondary, fontWeight: '700' },
  minimalRunner: { flex: 1, minHeight: 390, justifyContent: 'center', alignItems: 'center', paddingHorizontal: space.lg, gap: space.xxl },
  minimalMovement: { color: colors.ink, fontSize: 40, lineHeight: 48, fontWeight: '700', textAlign: 'center', paddingHorizontal: space.sm },
  minimalStartPrompt: { fontSize: 48, lineHeight: 56 },
  minimalTimerBlock: { alignSelf: 'stretch', alignItems: 'center', gap: space.sm },
  minimalPhaseLabel: { fontSize: 32, lineHeight: 40, fontWeight: '700', letterSpacing: 1.4, textAlign: 'center' },
  minimalTimer: { color: colors.ink, fontSize: 96, lineHeight: 112, fontWeight: '300', letterSpacing: -3, fontVariant: ['tabular-nums'], textAlign: 'center' },
  homeTitleRow: { flexDirection: 'row', alignItems: 'flex-start', justifyContent: 'space-between', gap: space.md },
  settingsButton: { minHeight: 48, justifyContent: 'center', paddingHorizontal: space.sm },
  settingsButtonText: { color: colors.accent, fontSize: text.secondary, lineHeight: 20, fontWeight: '700' },
  settingsContent: { paddingHorizontal: space.xl, paddingTop: space.xl },
  settingsRow: { minHeight: 80, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: space.lg, borderBottomWidth: StyleSheet.hairlineWidth, borderColor: colors.line },
  settingsCopy: { flex: 1, gap: space.xs },
  settingsTitle: { color: colors.ink, fontSize: text.body, lineHeight: 23, fontWeight: '700' },
  settingsDescription: { color: colors.secondary, fontSize: text.secondary, lineHeight: 20 },
  runnerStartPrompt: { fontSize: 40, lineHeight: 48, transform: [{ translateY: -14 }] },
  catalogueGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: space.sm },
  addMovementGrid: { minHeight: 136, flexBasis: '48%', flexGrow: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: space.sm, paddingVertical: space.md, borderRadius: 12, backgroundColor: colors.surfaceSoft, position: 'relative' },
  runnerFigureStage: { width: '58%', height: '80%', position: 'relative', justifyContent: 'flex-end' },
  runnerFigureFrame: { position: 'absolute', bottom: 0, width: '100%', height: '100%' },
  runnerSingleFigure: { width: '58%', height: '80%', alignSelf: 'center' },
  runnerStaticSequence: { width: '96%', height: '78%', flexDirection: 'row', alignItems: 'flex-end', justifyContent: 'center', gap: space.xs },
  runnerStaticPhase: { flex: 1, height: '100%', alignItems: 'center', justifyContent: 'flex-end' },
  runnerStaticFigure: { width: '100%', height: '100%' },
});

const makeExerciseDetailStyles = (colors: typeof dark) => StyleSheet.create({
  content: {
    flexGrow: 1,
    paddingHorizontal: space.xl,
    paddingBottom: space.xxl,
  },
  hero: {
    height: 288,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.surfaceSoft,
  },
  phaseSequence: {
    width: '100%',
    height: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: space.sm,
    paddingHorizontal: space.sm,
  },
  phaseGroup: {
    flex: 1,
    height: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  phaseFrame: {
    width: '100%',
    height: 238,
  },
  phaseNumber: {
    color: colors.accent,
    fontSize: text.label,
    lineHeight: 16,
    fontWeight: '700',
  },
  exerciseVisual: {
    width: '100%',
    height: '100%',
    opacity: 1,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: colors.line,
  },
  zones: {
    paddingTop: space.lg,
    paddingBottom: space.lg,
  },
  sectionTitle: {
    color: colors.ink,
    fontSize: text.title,
    lineHeight: 25,
    fontWeight: '700',
  },
  zoneVisual: {
    alignSelf: 'center',
    width: '74%',
    height: 164,
    marginTop: space.md,
    opacity: 1,
  },
  referenceRow: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.sm,
  },
  referenceIcon: {
    color: colors.secondary,
    fontSize: 21,
    lineHeight: 24,
  },
  referenceText: {
    flex: 1,
    color: colors.secondary,
    fontSize: text.secondary,
    lineHeight: 20,
  },
  referenceArrow: {
    color: colors.secondary,
    fontSize: 31,
    lineHeight: 32,
    fontWeight: '300',
  },
  footer: {
    paddingHorizontal: space.xl,
    paddingTop: space.md,
    paddingBottom: space.xxl + space.xs,
    backgroundColor: colors.background,
  },
  addButton: {
    minHeight: 56,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 14,
    backgroundColor: colors.accent,
  },
  addButtonText: {
    color: colors.accentText,
    fontSize: text.body,
    fontWeight: '700',
  },
});

const makeSaveNameStyles = (colors: typeof dark) => StyleSheet.create({
  backdrop: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0, 0, 0, 0.42)',
  },
  sheet: {
    padding: space.xl,
    paddingBottom: space.xxl,
    gap: space.md,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    backgroundColor: colors.surface,
  },
  title: {
    color: colors.ink,
    fontSize: text.title,
    lineHeight: 25,
    fontWeight: '700',
  },
  description: {
    color: colors.secondary,
    fontSize: text.body,
    lineHeight: 23,
  },
  input: {
    minHeight: 54,
    paddingHorizontal: space.md,
    color: colors.ink,
    fontSize: text.body,
    fontWeight: '600',
    borderWidth: 1,
    borderColor: colors.line,
    borderRadius: 12,
    backgroundColor: colors.background,
  },
  actions: {
    flexDirection: 'row',
    gap: space.md,
    marginTop: space.sm,
  },
  cancel: {
    minHeight: 56,
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 14,
    backgroundColor: colors.surfaceSoft,
  },
  cancelText: {
    color: colors.ink,
    fontSize: text.body,
    fontWeight: '700',
  },
  confirm: {
    minHeight: 56,
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 14,
    backgroundColor: colors.accent,
  },
  confirmText: {
    color: colors.accentText,
    fontSize: text.body,
    fontWeight: '700',
  },
});
