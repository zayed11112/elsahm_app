import React, { createContext, useState, useContext, ReactNode } from 'react';
import { ThemeProvider as MuiThemeProvider, createTheme } from '@mui/material/styles';
import { PaletteMode } from '@mui/material';
import rtlPlugin from 'stylis-plugin-rtl';
import { prefixer } from 'stylis';
import { CacheProvider } from '@emotion/react';
import createCache from '@emotion/cache';

// Create RTL cache
const cacheRtl = createCache({
  key: 'muirtl',
  stylisPlugins: [prefixer, rtlPlugin],
});

type ThemeContextType = {
  mode: PaletteMode;
  toggleMode: () => void;
  locale: string;
  setLocale: (locale: string) => void;
};

const ThemeContext = createContext<ThemeContextType>({
  mode: 'light',
  toggleMode: () => {},
  locale: 'ar',
  setLocale: () => {},
});

// Hook for easy context use
export const useThemeContext = () => useContext(ThemeContext);

interface ThemeProviderProps {
  children: ReactNode;
}

export const ThemeProvider = ({ children }: ThemeProviderProps) => {
  const [mode, setMode] = useState<PaletteMode>('light');
  const [locale, setLocale] = useState<string>('ar');

  // Create theme based on current mode
  const theme = createTheme({
    direction: 'rtl',
    palette: {
      mode,
      primary: {
        main: '#1976d2',
      },
      secondary: {
        main: '#f50057',
      },
    },
    typography: {
      fontFamily: [
        'Tajawal',
        'Roboto',
        'sans-serif',
      ].join(','),
    },
    components: {
      MuiButton: {
        styleOverrides: {
          root: {
            fontWeight: 'bold',
          },
        },
      },
      MuiTableCell: {
        styleOverrides: {
          root: {
            textAlign: 'right',
          },
        },
      },
    },
  });

  // Toggle between light and dark themes
  const toggleMode = () => {
    setMode((prevMode) => (prevMode === 'light' ? 'dark' : 'light'));
  };

  return (
    <ThemeContext.Provider value={{ mode, toggleMode, locale, setLocale }}>
      <CacheProvider value={cacheRtl}>
        <MuiThemeProvider theme={theme}>
          {children}
        </MuiThemeProvider>
      </CacheProvider>
    </ThemeContext.Provider>
  );
}; 