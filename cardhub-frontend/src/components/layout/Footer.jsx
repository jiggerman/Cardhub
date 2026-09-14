
import React from 'react';
import { Box, Typography, Container } from '@mui/material';

const Footer = () => {
  return (
    <Box
      component="footer"
      sx={{
        py: 3,
        mt: 'auto',
        borderTop: '1px solid',
        borderColor: 'divider',
        position: 'relative',
        '&::before': {
          content: '""',
          position: 'absolute',
          top: -1,
          left: 0,
          right: 0,
          height: '1px',
          background: (theme) =>
            `linear-gradient(90deg, transparent, ${theme.palette.primary.main}, transparent)`,
          opacity: 0.6,
        },
      }}
    >
      <Container maxWidth="lg">
        <Typography variant="body2" color="text.secondary" align="center" sx={{ letterSpacing: 0.2 }}>
          © {new Date().getFullYear()} CardHub. Все права защищены.
        </Typography>
      </Container>
    </Box>
  );
};

export default Footer;
