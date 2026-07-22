# Модель данных упражнения

Статус: проект структуры перед миграцией текущего каталога.

## Задача

Одна запись должна быть достаточна, чтобы:

- показать упражнение в каталоге и карточке;
- воспроизвести 2–3 фазы движения через плавную смену кадров;
- показать статичную схему всех фаз;
- выбрать мужскую или женскую фигуру из профиля;
- построить карту задействованных зон;
- проследить, какой источник подтверждает каждую техническую формулировку;
- автоматически проверить готовность упражнения к публикации.

Запись не хранит вес, повторения, подходы, индивидуальные интервалы и темп. Эти параметры не относятся к упражнению в продуктовой модели приложения.

## Предлагаемый контракт

```ts
type ExerciseId = string;
type PhaseId = string;
type FigureVariant = 'male' | 'female';

type ExercisePhase = {
  id: PhaseId;
  order: number;
  shortName: string;              // редакторская метка, не обязательный UI-текст
  technique: string;              // что должно происходить в этой фазе
  poseBrief: {
    bodyOrientation: 'front' | 'three_quarter' | 'side';
    support: 'bilateral' | 'left' | 'right' | 'transition';
    kettlebellPosition: string;
    bodyPosition: string;
  };
  visual: {
    feetBaseline: number;          // единый нормализованный уровень стоп 0..1
    scale: number;                 // единый визуальный масштаб фигуры
    assets: Partial<Record<FigureVariant, string>>;
    status: 'missing' | 'generated' | 'reviewed' | 'approved';
  };
};

type ExerciseSource = {
  id: string;
  organization: string;
  title: string;
  url: string;
  sourceType: 'professional_standard' | 'textbook' | 'research' | 'supplementary';
  accessedAt: string;
  supports: readonly string[];    // id утверждений, cues, фаз или зон
};

type ExerciseRecord = {
  schemaVersion: 2;
  id: ExerciseId;
  name: string;
  aliases: readonly string[];
  classification: {
    movementKind: 'ballistic' | 'grind' | 'complex';
    laterality: 'bilateral' | 'unilateral' | 'alternating';
    experience: 'basic' | 'intermediate' | 'advanced';
  };
  phases: readonly ExercisePhase[]; // ровно 2 или 3 для текущего runner-а
  cues: readonly {
    id: string;
    text: string;
    sourceIds: readonly string[];
  }[];
  anatomy: {
    primary: readonly string[];
    secondary: readonly string[];
    asset?: string;
    status: 'missing' | 'draft' | 'reviewed' | 'approved';
  };
  assets: {
    thumbnailPhaseId: PhaseId;
    styleId: 'approved-athlete-v1';
    anatomyStyleId: 'approved-anatomy-v1';
  };
  sources: readonly ExerciseSource[];
  review: {
    technique: 'draft' | 'source_checked' | 'coach_approved' | 'rejected';
    phases: 'draft' | 'reviewed' | 'approved';
    visuals: 'missing' | 'generated' | 'reviewed' | 'approved';
    anatomy: 'missing' | 'draft' | 'reviewed' | 'approved';
    reviewedAt?: string;
    reviewer?: string;
    notes?: string;
  };
};
```

## Почему фазы — центр модели

`phases` одновременно обслуживают оба режима runner-а:

- с анимацией приложение последовательно показывает `visual.assets[figureVariant]`;
- без анимации изображения не используются;
- карточка упражнения показывает все фазы рядом;
- `feetBaseline` и `scale` не дают фигуре прыгать между кадрами;
- `bodyOrientation` и `support` позволяют автоматически проверить ошибочную смену стороны.

Для текущего runner-а допускаются только 2 или 3 явные фазы. Более длинные последовательности не сокращаются автоматически: они получают статус `deferred` и отдельное продуктовое решение.

## Мужская и женская фигуры

Каждая фаза имеет независимые ассеты `male` и `female`, но одну технику, опорную линию и масштаб. Профиль выбирает вариант фигуры; логика упражнения от этого не меняется. Если нужного варианта нет, упражнение не считается визуально готовым для соответствующего профиля.

## Автоматическая отрисовка

Генератор получает не свободный текст, а стабильный пакет:

1. `styleId` утверждённой основной фигуры;
2. `FigureVariant`;
3. `poseBrief` текущей фазы;
4. соседние фазы как контекст последовательности;
5. одинаковые `feetBaseline`, `scale`, ракурс и холст;
6. требование прозрачного фона и запрет менять лицо, одежду и стиль линий.

После генерации автоматическая проверка сравнивает размер холста, прозрачность, уровень стоп, рабочую сторону и наличие гири. Масштаб определяется по длинам скелетных сегментов, а идентичность телосложения — по ширине головы и корпуса и толщине рук и ног. Bounding box всей фигуры не считается показателем масштаба. Подробный алгоритм описан в [контроле однородности фигур](VISUAL_CONSISTENCY_PIPELINE.md). Только прошедший автоматическую проверку кадр переходит в `reviewed`; статус `approved` остаётся ручным решением.

## Источники и проверяемость

Ссылка сама по себе недостаточна. Поле `supports` связывает источник с конкретными утверждениями, например:

```ts
supports: ['phase.hike.bodyPosition', 'cue.hip-drive', 'anatomy.glutes']
```

Так можно заменить сомнительную формулировку, не пересматривая всю карточку, и увидеть утверждения без надёжной опоры.

## Условия публикации

Упражнение появляется в пользовательском каталоге, только если:

1. фаз ровно 2 или 3, порядок уникален и непрерывен;
2. техника имеет статус минимум `source_checked`;
3. фазы подтверждены как минимум на уровне `reviewed`;
4. все нужные кадры существуют и имеют одинаковый визуальный контракт;
5. карта зон проверена и не содержит процентов или обещаний результата;
6. каждый опубликованный cue связан хотя бы с одним источником;
7. заданы миниатюра и утверждённые `styleId`;
8. нет веса, повторений, подходов или индивидуальных таймингов.

## Переход с текущей модели

Текущие поля преобразуются без потери данных:

| Сейчас | Версия 2 |
|---|---|
| `movementKind` | `classification.movementKind` |
| `keyPose` | первая редакторская заготовка для `phases` |
| `cueDrafts` | `cues` с отдельными id и `sourceIds` |
| `zoneMap` | `anatomy.primary` и `anatomy.secondary` после проверки |
| `sourceUrls` | структурированные `sources` |
| `runnerStatic` | ассет выбранной фазы |
| `motionReady` | вычисляется из фаз и статусов ассетов |

Миграция выполняется упражнение за упражнением. Старый каталог остаётся рабочим, пока новая запись не пройдёт валидацию и не даст те же пользовательские экраны без регрессии.
