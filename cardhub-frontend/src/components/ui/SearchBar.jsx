import React from 'react';
import {
  TextField,
  InputAdornment,
  IconButton,
  Paper
} from '@mui/material';
import { alpha } from '@mui/material/styles';
import SearchIcon from '@mui/icons-material/Search';
import ClearIcon from '@mui/icons-material/Clear';

const SearchBar = ({ onSearch }) => {
  const [query, setQuery] = React.useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    onSearch(query);
  };

  const handleClear = () => {
    setQuery('');
    onSearch('');
  };

  return (
    <Paper
      component="form"
      onSubmit={handleSubmit}
      elevation={0}
      sx={{
        width: '100%',
        maxWidth: 600,
        borderRadius: 999,
        border: '1px solid',
        borderColor: 'divider',
        backgroundColor: (theme) => alpha(theme.palette.background.paper, 0.7),
        backdropFilter: 'blur(8px)',
        transition: 'box-shadow 0.2s ease, border-color 0.2s ease',
        '&:focus-within': {
          borderColor: (theme) => alpha(theme.palette.primary.main, 0.6),
          boxShadow: (theme) => `0 0 0 4px ${alpha(theme.palette.primary.main, 0.18)}, 0 8px 24px rgba(0,0,0,0.35)`,
        },
      }}
    >
      <TextField
        fullWidth
        variant="outlined"
        placeholder="Введите название карты..."
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <SearchIcon color="primary" />
            </InputAdornment>
          ),
          endAdornment: query && (
            <InputAdornment position="end">
              <IconButton onClick={handleClear}>
                <ClearIcon />
              </IconButton>
            </InputAdornment>
          ),
          sx: {
            borderRadius: 999,
            '& fieldset': { border: 'none' },
          },
        }}
        sx={{
          '& .MuiOutlinedInput-root': {
            fontSize: '1.05rem',
            py: 0.75,
            px: 0.5,
          },
          '& .MuiOutlinedInput-root.Mui-focused': {
            boxShadow: 'none',
          },
        }}
      />
    </Paper>
  );
};

export default SearchBar;
