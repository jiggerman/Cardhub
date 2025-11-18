import React, { useState } from 'react';
import {
  Grid,
  Typography,
  Box,
  Pagination,
  CircularProgress,
  Alert
} from '@mui/material';
import { useCardSearch } from '../hooks/useCardSearch';
import Card from './Card';

const CardGrid = ({ searchQuery, onCardClick }) => {
  const [page, setPage] = useState(1);
  const { cards, loading, error, total } = useCardSearch(searchQuery, page);

  const handlePageChange = (event, value) => {
    setPage(value);
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" my={4}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ my: 2 }}>
        Ошибка при загрузке карточек: {error}
      </Alert>
    );
  }

  if (cards.length === 0 && searchQuery) {
    return (
      <Box textAlign="center" my={4}>
        <Typography variant="h6" color="text.secondary">
          По запросу "{searchQuery}" ничего не найдено
        </Typography>
      </Box>
    );
  }

  const totalPages = Math.ceil(total / 20);

  return (
    <Box sx={{ width: '100%', my: 4 }}>
      {total > 0 && (
        <Typography variant="subtitle1" color="text.secondary" mb={3}>
          Найдено карт: {total} (Страница {page} из {totalPages})
        </Typography>
      )}
      
      <Grid container spacing={3} justifyContent="center">
        {cards.map((card) => (
          <Grid item key={card.id}>
            <Card card={card} onCardClick={onCardClick} />
          </Grid>
        ))}
      </Grid>

      {totalPages > 1 && (
        <Box display="flex" justifyContent="center" mt={4}>
          <Pagination
            count={totalPages}
            page={page}
            onChange={handlePageChange}
            color="primary"
            size="large"
          />
        </Box>
      )}
    </Box>
  );
};

export default CardGrid;