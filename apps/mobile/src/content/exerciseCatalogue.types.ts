import type { ImageSourcePropType } from 'react-native';

export type FigureVariant = 'male' | 'female';

export type ExerciseRecordV2 = {
  schemaVersion: 2;
  id: string;
  name: string;
  aliases: readonly string[];
  classification: {
    movementKind: 'ballistic' | 'grind' | 'complex';
    laterality: 'bilateral' | 'unilateral' | 'alternating';
    experience: 'basic' | 'intermediate' | 'advanced';
  };
  phases: readonly {
    id: string;
    order: number;
    shortName: string;
    technique: string;
    poseBrief: {
      bodyOrientation: 'front' | 'three_quarter' | 'side';
      support: 'bilateral' | 'left' | 'right' | 'transition';
      kettlebellPosition: string;
      bodyPosition: string;
    };
    visual: {
      feetBaseline: number;
      scale: number;
      assets: Readonly<Record<FigureVariant, string>>;
      status: 'missing' | 'generated' | 'reviewed' | 'approved';
    };
  }[];
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
    thumbnailPhaseId: string;
    styleId: 'approved-athlete-v1';
    anatomyStyleId: 'approved-anatomy-v1';
  };
  sources: readonly {
    id: string;
    organization: string;
    title: string;
    url: string;
    sourceType: 'professional_standard' | 'textbook' | 'research' | 'supplementary';
    accessedAt: string;
    supports: readonly string[];
  }[];
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

export type ExerciseVisualSet = {
  thumbnail: Readonly<Record<FigureVariant, ImageSourcePropType>>;
  frames: Readonly<Record<FigureVariant, readonly ImageSourcePropType[]>>;
  anatomy?: ImageSourcePropType;
};
