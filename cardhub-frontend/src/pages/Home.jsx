import React, { useState } from 'react';
import { 
  Container, 
  Box, 
  Typography 
} from '@mui/material';
import SearchBar from '../components/ui/SearchBar';
import CardGrid from '../features/cards/components/CardGrid';
import CardPopup from '../features/cards/components/CardPopup';

const Home = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCard, setSelectedCard] = useState(null);
  const [isPopupOpen, setIsPopupOpen] = useState(false);

  const handleSearch = (query) => {
    setSearchQuery(query);
  };

  const handleCardClick = (card) => {
    setSelectedCard(card);
    setIsPopupOpen(true);
  };

  const handleClosePopup = () => {
    setIsPopupOpen(false);
    setSelectedCard(null);
  };

  return (
    <Container maxWidth="lg">
      {/* Поисковая строка в центре */}
      <Box
        sx={{
          minHeight: searchQuery ? '20vh' : '80vh',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          gap: 4,
          transition: 'min-height 0.3s ease'
        }}
      >      
        <SearchBar onSearch={handleSearch} />
      </Box>
      
      {/* Сетка карточек */}
      {searchQuery && (
        <CardGrid 
          searchQuery={searchQuery} 
          onCardClick={handleCardClick}
        />
      )}
      
      {/* Попап с деталями карточки */}
      <CardPopup
        open={isPopupOpen}
        onClose={handleClosePopup}
        card={selectedCard}
      />
    </Container>
  );
};

export default Home;
