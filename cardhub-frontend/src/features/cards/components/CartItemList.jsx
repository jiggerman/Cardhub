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
  Button
} from '@mui/material';
import { Add as AddIcon, Remove as RemoveIcon, Delete as DeleteIcon } from '@mui/icons-material';

const CartItemList = ({ 
  items, 
  title, 
  onQuantityChange, 
  onRemove,
  totalItems,
  totalPrice,
  showPrice = true // ← ДОБАВИЛИ ПАРАМЕТР
}) => {
  if (items.length === 0) {
    return null;
  }

  return (
    <Box sx={{ mb: 4 }}>
      <Typography variant="h5" gutterBottom>
        {title} ({totalItems} шт.)
      </Typography>
      
      {showPrice && ( // ← ПОКАЗЫВАЕМ ЦЕНУ ТОЛЬКО ЕСЛИ НУЖНО
        <Box sx={{ mb: 2 }}>
          <Typography variant="body2" color="text.secondary">
            Итого: {totalPrice} ₽
          </Typography>
        </Box>
      )}

      {items.map((item, index) => (
        <Box key={`${item.card.id}-${item.quality}-${index}`}>
          <Card sx={{ display: 'flex', mb: 2, p: 2 }}>
            <CardMedia
              component="img"
              sx={{ width: 100, height: 140, objectFit: 'contain', mr: 2, borderRadius: 2 }}
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

                {showPrice && item.card.minPrice && ( // ← ЦЕНУ ПОКАЗЫВАЕМ ТОЛЬКО ДЛЯ ПОКУПОК
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
          
          {index < items.length - 1 && <Divider sx={{ my: 2 }} />}
        </Box>
      ))}
    </Box>
  );
};

export default CartItemList;