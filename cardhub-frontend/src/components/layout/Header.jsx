import React from 'react';
import { IconButton, AppBar, Toolbar, Button, Box, Avatar } from '@mui/material';
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
    <AppBar position="static" sx={{ bgcolor: 'background.paper' }}>
      <Toolbar sx={{ justifyContent: 'space-between' }}>
        {/* Логотип слева */}
        <Box 
          component={Link}
          to="/" 
          sx={{
            display: 'flex',
            alignItems: 'center',
            textDecoration: 'none',
            color: 'inherit'
          }}
        >
          <img 
            src={logo}
            alt="Cardhub" 
            style={{ 
              height: 40, 
              width: 'auto',
              marginRight: 8 
            }} 
          />
        </Box>
        
        {/* Аватар справа */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <IconButton color="inherit" component={Link} to="/cart">
            <CartIcon />
          </IconButton>

          {isAuthenticated() ? (
            <Avatar 
              component={Link}
              to="/profile"
              sx={{ 
                width: 32, 
                height: 32, 
                bgcolor: 'primary.main',
                fontSize: '0.9rem',
                cursor: 'pointer',
                textDecoration: 'none'
              }}
            >
              {getInitials()}
            </Avatar>
          ) : (
            <Button 
              color="inherit" 
              component={Link} 
              to="/auth"
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