import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogContent,
  DialogTitle,
  IconButton,
  Typography,
  Box,
  Chip,
  Button,
  Divider,
  CircularProgress,
  Alert,
  Grid
} from '@mui/material';
import {
  Close as CloseIcon,
  AddShoppingCart as CartIcon
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import magic_card_back from '../../../Magic_card_back.webp'

const StyledDialog = styled(Dialog)(({ theme }) => ({
  '& .MuiDialog-paper': {
    backgroundColor: theme.palette.background.paper,
    backgroundImage: 'none',
    maxWidth: '800px',
    width: '90%',
    margin: '20px', 
  },
}));

const ColorChip = styled(Chip)(({ cardcolor }) => ({
  backgroundColor: getColorValue(cardcolor),
  color: getTextColor(cardcolor),
  fontWeight: 'bold',
  fontSize: '0.9rem',
}));

function getColorValue(color) {
  const colorMap = {
    'Red': '#f44336',
    'Blue': '#2196f3',
    'Green': '#4caf50',
    'White': '#ffffff',
    'Black': '#000000',
    'Multicolor': '#ff9800',
    'Colorless': '#9e9e9e'
  };
  return colorMap[color] || '#78909c';
}

function getTextColor(color) {
  return color === 'White' ? '#000000' : '#ffffff';
}

const CardPopup = ({ open, onClose, card }) => {  // ← Получаем card вместо cardId
  const [quantity, setQuantity] = useState(1);
  const [selectedQuality, setSelectedQuality] = useState('NM');
  const [imageError, setImageError] = useState(false);
  //const hasValidImage = card.imageUrlNormal && card.imageUrlNormal.trim() !== '';

  /*useEffect(() => {
      if (hasValidImage) {
        setImageError(false);
      } else {
        setImageError(true); // Нет изображения - сразу показываем заглушку
      }
    }, [card.imageUrlNormal, hasValidImage]);*/

  useEffect(() => {
    if (open) {
      setQuantity(1);
      setImageError(false);
    }
  }, [open]);

  const handleAddToCart = () => {
    console.log('Add to cart:', { card, quantity });
  };

  const handleClose = () => {
    setQuantity(1);
    setImageError(false);
    onClose();
  };

  const handleImageError = () => {
    setImageError(true);
  };

  if (!open || !card) return null;

  return (
    <StyledDialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle sx={{ 
        display: 'flex', 
        justifyContent: 'flex-end', 
        alignItems: 'center',
        p: 1,
        pb: 0
      }}>
        <IconButton onClick={handleClose}>
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent sx={{ p: 3 }}>
        <Grid container spacing={4}>
          {/* Medium изображение карты */}
          <Grid item xs={12} md={6} sx={{ pr: 1 }}>
            <Box
              component="img"
              src={imageError ? magic_card_back : card.imageUrlNormal}
              alt={card.name}
              onError={handleImageError}
              sx={{
                width: '100%',
                maxWidth: 400,
                height: 'auto',
                borderRadius: 6,
                backgroundColor: '#2d2d2d',
                boxShadow: '0 8px 32px rgba(0,0,0,0.3)'
              }}
            />
          </Grid>

          {/* Информация о карте */}
          <Grid item xs={12} md={6} sx={{ width: '100%', flex: 1 }}>
            <Typography variant="h4" gutterBottom fontWeight="600">
              {card.name}
            </Typography>

            <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
              <ColorChip 
                label={card.color} 
                cardcolor={card.color}
              />
              <Chip 
                label={card.type} 
                variant="outlined"
              />
            </Box>

            {/* Информация о сете */}
            <Box sx={{ mb: 3 }}>
              <Typography variant="h6" gutterBottom color="primary">
                Информация о карте
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography color="text.secondary">Сет:</Typography>
                  <Typography fontWeight="500">{card.setName}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography color="text.secondary">Номер в сете:</Typography>
                  <Typography fontWeight="500">#{card.collectorNumber}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography color="text.secondary">Код сета:</Typography>
                  <Typography fontWeight="500">{card.setCode}</Typography>
                </Box>
              </Box>
            </Box>

            <Divider sx={{ my: 2 }} />

            {/* Информация о покупке */}
            <Box sx={{ mb: 3, maxWidth: '100%'}}>
              <Typography variant="h6" gutterBottom color="primary">
                {card.isPreorder ? 'Предзаказ' : 'В наличии'}
              </Typography>
              
              {card.isPreorder ? (
                <>
                  <Typography color="text.secondary" paragraph>
                    Эта карта доступна для предзаказа.
                  </Typography>
                  {/* Выбор качества */}
                  <Box sx={{ mb: 2 }}>
                    <Typography gutterBottom>Качество:</Typography>
                    <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                      {['NM', 'SP', 'HP', 'MP', 'DM'].map((quality) => (
                        <Chip
                          key={quality}
                          label={quality}
                          variant={selectedQuality === quality ? "filled" : "outlined"}
                          onClick={() => setSelectedQuality(quality)}
                          color={selectedQuality === quality ? "primary" : "default"}
                          size="small"
                        />
                      ))}
                    </Box>
                  </Box>

                  {/* Выбор количества */}
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
                    <Typography>Количество:</Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <IconButton 
                        size="small"
                        onClick={() => setQuantity(Math.max(1, quantity - 1))}
                        disabled={quantity <= 1}
                        sx={{ border: '1px solid', borderColor: 'divider' }}
                      >
                        -
                      </IconButton>
                      <Typography sx={{ minWidth: 30, textAlign: 'center', fontWeight: 'bold' }}>
                        {quantity}
                      </Typography>
                      <IconButton 
                        size="small"
                        onClick={() => setQuantity(Math.min(4, quantity + 1))}
                        disabled={quantity >= 4}
                        sx={{ border: '1px solid', borderColor: 'divider' }}
                      >
                        +
                      </IconButton>
                    </Box>
                  </Box>
                </>
              ) : (
                <>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography>В наличии:</Typography>
                    <Typography fontWeight="bold" color="success.main">
                      {card.inStock} шт.
                    </Typography>
                  </Box>

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                    <Typography>Цена от:</Typography>
                    <Typography variant="h6" color="primary">
                      {card.minPrice} ₽
                    </Typography>
                  </Box>

                  {card.availableQualities && card.availableQualities.length > 0 && (
                    <Box sx={{ mb: 2 }}>
                      <Typography color="text.secondary" variant="body2">
                        Доступные качества: {card.availableQualities.join(', ')}
                      </Typography>
                    </Box>
                  )}

                  {/* Выбор количества */}
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
                    <Typography>Количество:</Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <IconButton 
                        size="small"
                        onClick={() => setQuantity(Math.max(1, quantity - 1))}
                        disabled={quantity <= 1}
                        sx={{ border: '1px solid', borderColor: 'divider' }}
                      >
                        -
                      </IconButton>
                      <Typography sx={{ minWidth: 30, textAlign: 'center', fontWeight: 'bold' }}>
                        {quantity}
                      </Typography>
                      <IconButton 
                        size="small"
                        onClick={() => setQuantity(Math.min(card.inStock, quantity + 1))}
                        disabled={quantity >= card.inStock}
                        sx={{ border: '1px solid', borderColor: 'divider' }}
                      >
                        +
                      </IconButton>
                    </Box>
                  </Box>
                </>
              )}

              {/* Кнопка добавления в корзину */}
              <Button
                variant="contained"
                size="large"
                fullWidth
                startIcon={<CartIcon />}
                onClick={handleAddToCart}
                disabled={card.isPreorder ? false : card.inStock === 0}
                sx={{ py: 1.5 }}
              >
                {card.isPreorder ? 'Оформить предзаказ' : 
                 card.inStock === 0 ? 'Нет в наличии' : 'Добавить в корзину'}
              </Button>
            </Box>
          </Grid>
        </Grid>
      </DialogContent>
    </StyledDialog>
  );
};

export default CardPopup;