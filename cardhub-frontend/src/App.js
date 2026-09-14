import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme, alpha } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { Box } from '@mui/material';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import Header from './components/layout/Header';
import Footer from './components/layout/Footer';
import Home from './pages/Home';
import Auth from './pages/Auth';
import Profile from './pages/Profile';
import { CartProvider } from './contexts/CartContext';
import Cart from './pages/Cart';
import './App.css';

const PRIMARY = { main: '#7e57c2', light: '#a389d9', dark: '#5e35b1' };
const SECONDARY = { main: '#78909c', light: '#a7c0cd', dark: '#4b636e' };

let theme = createTheme({
  palette: {
    mode: 'dark',
    primary: PRIMARY,
    secondary: SECONDARY,
    background: {
      default: '#0f0b17',
      paper: '#1a1626',
    },
    divider: 'rgba(255, 255, 255, 0.08)',
    text: {
      primary: 'rgba(255, 255, 255, 0.94)',
      secondary: 'rgba(255, 255, 255, 0.62)',
    },
  },
  shape: {
    borderRadius: 14,
  },
  typography: {
    fontFamily: "'Manrope', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
    h3: { fontWeight: 800, letterSpacing: '-0.02em' },
    h4: { fontWeight: 700, letterSpacing: '-0.01em' },
    h5: { fontWeight: 700 },
    h6: { fontWeight: 600 },
    button: { fontWeight: 600, textTransform: 'none' },
  },
});

theme = createTheme(theme, {
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        html: {
          backgroundColor: '#0f0b17',
        },
        body: {
          backgroundColor: '#0f0b17',
          backgroundImage:
            'radial-gradient(ellipse 900px 600px at 12% -10%, rgba(126, 87, 194, 0.22), transparent 60%),' +
            'radial-gradient(ellipse 800px 500px at 90% 10%, rgba(120, 144, 156, 0.14), transparent 55%),' +
            'radial-gradient(ellipse 900px 700px at 50% 100%, rgba(126, 87, 194, 0.10), transparent 60%)',
          backgroundRepeat: 'no-repeat',
          backgroundAttachment: 'fixed',
          minHeight: '100vh',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: alpha(theme.palette.background.paper, 0.72),
          backgroundImage: 'none',
          backdropFilter: 'blur(16px)',
          WebkitBackdropFilter: 'blur(16px)',
          borderBottom: `1px solid ${theme.palette.divider}`,
          boxShadow: 'none',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
        },
        outlined: {
          borderColor: theme.palette.divider,
        },
        elevation1: {
          boxShadow: '0 1px 2px rgba(0,0,0,0.4)',
        },
        elevation3: {
          border: `1px solid ${theme.palette.divider}`,
          boxShadow: '0 12px 32px rgba(0,0,0,0.35)',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
          border: `1px solid ${theme.palette.divider}`,
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 10,
          paddingInline: 18,
          transition: 'transform 0.18s ease, box-shadow 0.18s ease, background-color 0.18s ease',
        },
        contained: {
          backgroundImage: `linear-gradient(135deg, ${PRIMARY.main}, ${PRIMARY.dark})`,
          boxShadow: `0 6px 18px ${alpha(PRIMARY.main, 0.35)}`,
          '&:hover': {
            backgroundImage: `linear-gradient(135deg, ${PRIMARY.light}, ${PRIMARY.main})`,
            boxShadow: `0 8px 22px ${alpha(PRIMARY.main, 0.45)}`,
            transform: 'translateY(-1px)',
          },
        },
        outlined: {
          borderColor: alpha(PRIMARY.main, 0.5),
          '&:hover': {
            borderColor: PRIMARY.light,
            backgroundColor: alpha(PRIMARY.main, 0.08),
            transform: 'translateY(-1px)',
          },
        },
        text: {
          '&:hover': {
            backgroundColor: alpha(PRIMARY.main, 0.08),
          },
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          fontWeight: 600,
        },
      },
    },
    MuiOutlinedInput: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          transition: 'box-shadow 0.18s ease, border-color 0.18s ease',
          '&:hover .MuiOutlinedInput-notchedOutline': {
            borderColor: alpha(PRIMARY.main, 0.6),
          },
          '&.Mui-focused': {
            boxShadow: `0 0 0 3px ${alpha(PRIMARY.main, 0.22)}`,
          },
        },
      },
    },
    MuiDialog: {
      styleOverrides: {
        paper: {
          borderRadius: 20,
          border: `1px solid ${theme.palette.divider}`,
          backgroundImage: 'none',
        },
      },
    },
    MuiBackdrop: {
      styleOverrides: {
        root: {
          backgroundColor: alpha('#0a0712', 0.72),
          backdropFilter: 'blur(4px)',
        },
      },
    },
    MuiAlert: {
      styleOverrides: {
        root: {
          borderRadius: 12,
        },
      },
    },
    MuiAvatar: {
      styleOverrides: {
        root: {
          backgroundImage: `linear-gradient(135deg, ${PRIMARY.light}, ${PRIMARY.dark})`,
        },
      },
    },
  },
});

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  
  if (loading) {
    return <div>Загрузка...</div>;
  }
  
  return isAuthenticated() ? children : <Navigate to="/auth" />;
};

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <CartProvider>
          <Router>
            <Box sx={{ 
              display: 'flex', 
              flexDirection: 'column', 
              minHeight: '100vh' 
            }}>
              <Header />
              <Box component="main" sx={{ flexGrow: 1 }}>
                <Routes>
                  <Route path="/" element={<Home />} />
                  <Route path="/auth" element={<Auth />} />
                  <Route 
                    path="/profile" 
                    element={
                      <ProtectedRoute>
                        <Profile />
                      </ProtectedRoute>
                    } 
                  />
                  <Route path="/cart" element={<Cart />} />
                </Routes>
              </Box>
              <Footer />
            </Box>
          </Router>
        </CartProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;