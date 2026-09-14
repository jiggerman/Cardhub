import React, { useState, useEffect } from 'react';
import {
  Card as MuiCard,
  CardMedia,
  CardContent,
  Typography,
  Box,
  Chip
} from '@mui/material';
import { styled, alpha } from '@mui/material/styles';
import magic_card_back from '../../../Magic_card_back.webp'

const CARD_WIDTH = 245;
const CARD_HEIGHT = 341.39;
// Скругление именно картинки карты. Задано в px и не завязано на theme.shape.borderRadius
// (MUI умножает числовые sx-значения borderRadius на theme.shape.borderRadius, поэтому здесь нужна строка с единицей).
// Важно: сами изображения Scryfall (image_uris.normal) уже содержат белый фон в углах
// (у физической карты скруглённые углы, а файл-скан прямоугольный). Проверено пиксельным анализом:
// при ширине карточки ~245px нужно минимум 14px, иначе в углах виден белый обрезок этого фона.
const CARD_IMAGE_RADIUS = '14px';

const StatusBadge = styled(Box, {
  shouldForwardProp: (prop) => prop !== 'status'
})(({ theme, status }) => ({
  position: 'absolute',
  top: 10,
  right: 10,
  padding: '4px 10px',
  borderRadius: 999,
  fontSize: '0.7rem',
  fontWeight: 700,
  letterSpacing: 0.2,
  zIndex: 1,
  backdropFilter: 'blur(6px)',
  backgroundColor: status === 'preorder' ? 'rgba(255, 152, 0, 0.88)' : 'rgba(76, 175, 80, 0.88)',
  color: '#0f0b17',
  boxShadow: '0 2px 8px rgba(0,0,0,0.35)',
}));

const ColorChip = styled(Chip, {
  shouldForwardProp: (prop) => prop !== 'cardcolor'
})(({ theme, cardcolor }) => ({
  backgroundColor: getColorValue(cardcolor),
  color: getTextColor(cardcolor),
  fontWeight: 'bold',
  fontSize: '0.75rem',
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

const StyledCard = styled(MuiCard)(({ theme }) => ({
  cursor: 'pointer',
  transition: 'transform 0.25s ease, box-shadow 0.25s ease, border-color 0.25s ease',
  width: CARD_WIDTH,
  height: CARD_HEIGHT + 120,
  display: 'flex',
  flexDirection: 'column',
  position: 'relative',
  // Скругление всей карточки = CARD_IMAGE_RADIUS, чтобы верх картинки и низ текстового блока совпадали визуально
  borderRadius: CARD_IMAGE_RADIUS,
  overflow: 'hidden',
  '&:hover': {
    transform: 'translateY(-6px)',
    boxShadow: `0 16px 32px -8px ${alpha(theme.palette.primary.main, 0.45)}`,
    borderColor: alpha(theme.palette.primary.main, 0.6),
  },
}));

const Card = ({ card, onCardClick }) => {
  const [imageError, setImageError] = useState(false);

  // Автоматически показываем запасное изображение если URL пустой или отсутствует
  const hasValidImage = card.imageUrlNormal && card.imageUrlNormal.trim() !== '';

  useEffect(() => {
    if (hasValidImage) {
      setImageError(false);
    } else {
      setImageError(true); // Нет изображения - сразу показываем заглушку
    }
  }, [card.imageUrlNormal, hasValidImage]);

  const handleClick = () => {
    if (onCardClick) {
      onCardClick(card);
    }
  };

  const handleImageError = () => {
    console.warn(`Image failed to load: ${card.imageUrlNormal}`);
    setImageError(true);
  };

  return (
    <StyledCard variant="outlined" onClick={handleClick}>
      {/* Бейдж статуса */}
      {card.isPreorder ? (
        <StatusBadge status="preorder">ПРЕДЗАКАЗ</StatusBadge>
      ) : (
        <StatusBadge status="instock">
          В НАЛИЧИИ {card.minPrice}₽
        </StatusBadge>
      )}

      <CardMedia
        component="img"
        height={CARD_HEIGHT}
        image={!hasValidImage || imageError ? magic_card_back : card.imageUrlNormal}
        alt={card.name || 'Magic Card'}
        onError={handleImageError}
        sx={{
          // Скругление на всех 4 углах картинки: сам файл Scryfall (image_uris.normal) содержит
          // белый фон в углах (см. комментарий у CARD_IMAGE_RADIUS) — это касается не только верха,
          // но и низа картинки, хотя низ визуально примыкает к CardContent, а не является углом карточки.
          borderRadius: CARD_IMAGE_RADIUS,
          objectFit: 'cover',
          backgroundColor: '#2d2d2d',
          width: '100%',
          height: CARD_HEIGHT
        }}
      />
      <CardContent sx={{ 
        flexGrow: 1, 
        p: 1.5,
        display: 'flex',
        flexDirection: 'column',
        height: 120
      }}>
        <Typography variant="subtitle1" component="h3" gutterBottom noWrap sx={{ fontSize: '0.9rem', lineHeight: 1.2 }}>
          {card.name || 'Unnamed Card'}
        </Typography>
        
        <Box sx={{ display: 'flex', gap: 0.5, mb: 1, flexWrap: 'wrap' }}>
          <ColorChip 
            label={card.color || 'Colorless'} 
            cardcolor={card.color || 'Colorless'} 
            size="small" 
          />
          <Chip 
            label={card.type || 'Unknown'} 
            variant="outlined" 
            size="small" 
            sx={{ fontSize: '0.7rem', height: 24 }} 
          />
        </Box>
        
        <Typography variant="body2" color="text.secondary" noWrap sx={{ fontSize: '0.8rem', mt: 'auto' }}>
          {card.setName || 'Unknown Set'}
        </Typography>
        <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.7rem' }}>
          #{card.collectorNumber || '000'}
        </Typography>
      </CardContent>
    </StyledCard>
  );
};

export default Card;