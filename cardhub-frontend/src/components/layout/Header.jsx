import React from 'react';
import { AppBar, Toolbar, Typography, Button, Box, Avatar } from '@mui/material';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

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
        <Typography 
          variant="h6" 
          component={Link} 
          to="/"
          sx={{ 
            textDecoration: 'none', 
            color: 'inherit',
            fontWeight: 'bold'
          }}
        >
          CARDS STORE
        </Typography>
        
        {/* Аватар справа */}
        <Box>
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