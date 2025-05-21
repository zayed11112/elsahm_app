// This file adds type overrides for Material UI components
import { ElementType } from 'react';
import { SxProps, Theme } from '@mui/material/styles';

declare module '@mui/material/Grid' {
  interface GridTypeMap {
    props: {
      item?: boolean;
      container?: boolean;
      spacing?: number | string;
      xs?: number | boolean;
      sm?: number | boolean;
      md?: number | boolean;
      lg?: number | boolean;
      xl?: number | boolean;
      component?: ElementType;
    };
  }
} 