import React from 'react';
import { IconButton, AppBar, Toolbar, Button, Box, Avatar } from '@mui/material';
import { alpha } from '@mui/material/styles';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import CartIcon from './CartIcon';

import logo from '../../logo.png'

const Header = () => {
  const { user, isAuthenticated } = useAuth();
  const navigate = useNavigate();

  // Генерируем инициалы для аватара
  const getInitials = () => {
    if (user?.username) {
      return user.username.charAt(0).toUpperCase();
    }
    if (user?.email) {
      return user.email.charAt(0).toUpperCase();
    }
    return 'U';
  };

  return (
    <AppBar position="sticky" elevation={0}>
      <Toolbar sx={{ justifyContent: 'space-between', py: 0.5 }}>
        {/* Логотип слева */}
        <Box
          component={Link}
          to="/"
          sx={{
            display: 'flex',
            alignItems: 'center',
            textDecoration: 'none',
            color: 'inherit',
            transition: 'transform 0.2s ease',
            '&:hover': { transform: 'scale(1.03)' }
          }}
        >
          <img
            src={logo}
            alt="Cardhub"
            style={{
              height: 36,
              width: 'auto',
              marginRight: 8
            }}
          />
        </Box>

        {/* Аватар справа */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <IconButton
            color="inherit"
            component={Link}
            to="/cart"
            sx={{
              transition: 'background-color 0.18s ease',
              '&:hover': { backgroundColor: (theme) => alpha(theme.palette.primary.main, 0.12) }
            }}
          >
            <CartIcon />
          </IconButton>

          {isAuthenticated() ? (
            <Avatar
              component={Link}
              to="/profile"
              sx={{
                width: 34,
                height: 34,
                fontSize: '0.9rem',
                fontWeight: 700,
                cursor: 'pointer',
                textDecoration: 'none',
                border: '2px solid',
                borderColor: (theme) => alpha(theme.palette.primary.light, 0.5),
                transition: 'transform 0.18s ease, border-color 0.18s ease',
                '&:hover': {
                  transform: 'scale(1.06)',
                  borderColor: 'primary.light',
                }
              }}
            >
              {getInitials()}
            </Avatar>
          ) : (
            <Button
              variant="outlined"
              component={Link}
              to="/auth"
              sx={{ borderRadius: 999, px: 2.5 }}
            >
              Войти
            </Button>
          )}
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Header;