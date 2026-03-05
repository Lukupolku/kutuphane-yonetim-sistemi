export type SchoolType = 'ILKOKUL' | 'ORTAOKUL' | 'LISE';

export interface School {
  id: string;
  name: string;
  province: string;
  district: string;
  schoolType: SchoolType;
  ministryCode: string;
}
