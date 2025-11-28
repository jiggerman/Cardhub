import React from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  CardMedia,
  IconButton,
  Chip,
  Divider,
  Button,
  useTheme,
  useMediaQuery
} from '@mui/material';
import { Add as AddIcon, Remove as RemoveIcon, Delete as DeleteIcon } from '@mui/icons-material';

const CartItemList = ({ 
  items, 
  title, 
  onQuantityChange, 
  onRemove,
  totalItems,
  totalPrice,
  showPrice = true
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));

  if (items.length === 0) {
    return null;
  }

  return (
    <Box sx={{ mb: 4 }}>
      <Typography variant="h5" gutterBottom>
        {title} ({totalItems} шт.)
      </Typography>
      
      {showPrice && (
        <Box sx={{ mb: 2 }}>
          <Typography variant="body2" color="text.secondary">
            Итого: {totalPrice} ₽
          </Typography>
        </Box>
      )}

      {items.map((item, index) => (
        <Box key={`${item.card.id}-${item.quality}-${index}`}>
          {isMobile ? (
            // МОБИЛЬНАЯ ВЕРСИЯ
            <Card sx={{ mb: 2, p: 2 }}>
              {/* Картинка и заголовок в одной строке */}
              <Box sx={{ display: 'flex', alignItems: 'flex-start', mb: 2 }}>
                <CardMedia
                  component="img"
                  sx={{ width: 80, height: 112, objectFit: 'contain', mr: 2 }}
                  image={item.card.imageUrlNormal}
                  alt={item.card.name}
                />
                <Box sx={{ flex: 1 }}>
                  <Typography variant="h6" sx={{ fontSize: '1rem', mb: 1 }}>
                    {item.card.name}
                  </Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                    {item.card.setName}
                  </Typography>
                  <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                    <Chip label={item.card.color} size="small" variant="outlined" sx={{ fontSize: '0.7rem', height: 24 }} />
                    <Chip label={item.quality} size="small" color="primary" sx={{ fontSize: '0.7rem', height: 24 }} />
                    {item.card.isPreorder && (
                      <Chip label="Предзаказ" size="small" color="warning" sx={{ fontSize: '0.7rem', height: 24 }} />
                    )}
                  </Box>
                </Box>
              </Box>

              {/* Цена (если нужно) и управление */}
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                {showPrice && item.card.minPrice && (
                  <Box>
                    <Typography variant="h6" color="primary">
                      {item.card.minPrice * item.quantity} ₽
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {item.card.minPrice} ₽ × {item.quantity}
                    </Typography>
                  </Box>
                )}
                
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <IconButton 
                    size="small"
                    onClick={() => onQuantityChange(item.card.id, item.quality, item.quantity - 1)}
                  >
                    <RemoveIcon fontSize="small" />
                  </IconButton>
                  
                  <Typography sx={{ minWidth: 30, textAlign: 'center', fontWeight: 'bold' }}>
                    {item.quantity}
                  </Typography>
                  
                  <IconButton 
                    size="small"
                    onClick={() => onQuantityChange(item.card.id, item.quality, item.quantity + 1)}
                  >
                    <AddIcon fontSize="small" />
                  </IconButton>
                </Box>
              </Box>

              {/* Кнопка удаления */}
              <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 1 }}>
                <Button 
                  color="error" 
                  size="small"
                  startIcon={<DeleteIcon />}
                  onClick={() => onRemove(item.card.id, item.quality)}
                >
                  Удалить
                </Button>
              </Box>
            </Card>
          ) : (
            // ДЕСКТОПНАЯ ВЕРСИЯ (оставляем как было)
            <Card sx={{ display: 'flex', mb: 2, p: 2 }}>
              <CardMedia
                component="img"
                sx={{ width: 100, height: 140, objectFit: 'contain', mr: 2 }}
                image={item.card.imageUrlNormal}
                alt={item.card.name}
              />
              
              <CardContent sx={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <Box>
                    <Typography variant="h6" gutterBottom>
                      {item.card.name}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {item.card.setName} • #{item.card.collectorNumber}
                    </Typography>
                    <Box sx={{ mt: 1, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                      <Chip label={item.card.color} size="small" variant="outlined" />
                      <Chip label={`Качество: ${item.quality}`} size="small" color="primary" />
                      {item.card.isPreorder && (
                        <Chip label="Предзаказ" size="small" color="warning" />
                      )}
                    </Box>
                  </Box>

                  {showPrice && item.card.minPrice && (
                    <Box sx={{ textAlign: 'right' }}>
                      <Typography variant="h6" color="primary" gutterBottom>
                        {item.card.minPrice * item.quantity} ₽
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {item.card.minPrice} ₽ × {item.quantity}
                      </Typography>
                    </Box>
                  )}
                </Box>

                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mt: 'auto' }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <IconButton 
                      size="small"
                      onClick={() => onQuantityChange(item.card.id, item.quality, item.quantity - 1)}
                    >
                      <RemoveIcon />
                    </IconButton>
                    
                    <Typography sx={{ minWidth: 40, textAlign: 'center' }}>
                      {item.quantity}
                    </Typography>
                    
                    <IconButton 
                      size="small"
                      onClick={() => onQuantityChange(item.card.id, item.quality, item.quantity + 1)}
                    >
                      <AddIcon />
                    </IconButton>
                  </Box>

                  <Button 
                    color="error" 
                    startIcon={<DeleteIcon />}
                    onClick={() => onRemove(item.card.id, item.quality)}
                  >
                    Удалить
                  </Button>
                </Box>
              </CardContent>
            </Card>
          )}
          
          {index < items.length - 1 && <Divider sx={{ my: 2 }} />}
        </Box>
      ))}
    </Box>
  );
};

export default CartItemList;