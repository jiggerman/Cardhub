import React from 'react';
import {
  Container,
  Typography,
  Box,
  Paper,
  Button,
  Divider,
  Alert
} from '@mui/material';
import { ShoppingCartCheckout, CalendarToday } from '@mui/icons-material';
import { useCart } from '../contexts/CartContext';
import { useNavigate } from 'react-router-dom';
import CartItemList from '../features/cards/components/CartItemList';

const Cart = () => {
  const { 
    cartItems, 
    removeFromCart, 
    updateQuantity, 
    clearCart, 
    getCartTotal,
    getPurchaseItems,
    getPreorderItems,
    getPurchaseTotal,
    getPreorderTotal,
    getPurchaseCount,
    getPreorderCount,
    maxCartItems 
  } = useCart();
  const navigate = useNavigate();

  const handleQuantityChange = (cardId, quality, newQuantity) => {
    if (newQuantity < 1) {
      removeFromCart(cardId, quality);
    } else {
      updateQuantity(cardId, quality, newQuantity);
    }
  };

  const handleCheckoutPurchase = () => {
    const purchaseItems = getPurchaseItems();
    console.log('Оформление покупки:', purchaseItems);
    alert('Функция оформления покупки в разработке');
  };

  const handleCheckoutPreorder = () => {
    const preorderItems = getPreorderItems();
    console.log('Оформление предзаказа:', preorderItems);
    alert('Функция оформления предзаказа в разработке');
  };

  const handleCheckoutAll = () => {
    console.log('Оформление всего заказа:', cartItems);
    alert('Функция оформления заказа в разработке');
  };

  if (cartItems.length === 0) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Paper elevation={3} sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="h4" gutterBottom>
            Корзина пуста
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
            Добавьте карты из каталога чтобы сделать заказ
          </Typography>
          <Button 
            variant="contained" 
            size="large"
            onClick={() => navigate('/')}
          >
            Перейти к покупкам
          </Button>
        </Paper>
      </Container>
    );
  }

  const purchaseItems = getPurchaseItems();
  const preorderItems = getPreorderItems();
  const purchaseTotal = getPurchaseTotal();
  const preorderTotal = getPreorderTotal();
  const hasPurchase = purchaseItems.length > 0;
  const hasPreorder = preorderItems.length > 0;
  const totalPrice = getCartTotal();

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h3" component="h1" gutterBottom>
        Корзина
      </Typography>

      <Alert severity="info" sx={{ mb: 3 }}>
        Максимальное количество карт в корзине: {maxCartItems}. 
        Текущее количество: {getPurchaseCount() + getPreorderCount()}
      </Alert>

      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
        
        {/* СЕКЦИЯ ПОКУПКИ */}
        {hasPurchase && (
          <Paper elevation={3} sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
              <Typography variant="h4" color="primary">
                🛒 Покупка
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Typography variant="h6">
                  Итого: {purchaseTotal} ₽
                </Typography>
                <Button 
                  variant="contained"
                  startIcon={<ShoppingCartCheckout />}
                  onClick={handleCheckoutPurchase}
                  size="large"
                >
                  Оформить покупку
                </Button>
              </Box>
            </Box>

            <CartItemList
              items={purchaseItems}
              onQuantityChange={handleQuantityChange}
              onRemove={removeFromCart}
              totalItems={getPurchaseCount()}
              totalPrice={purchaseTotal}
            />
          </Paper>
        )}

        {/* СЕКЦИЯ ПРЕДЗАКАЗА */}
        {hasPreorder && (
            <Paper elevation={3} sx={{ p: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h4">
                    📅 Предзаказ
                </Typography>
                <Button 
                    variant="outlined"
                    color="warning"
                    startIcon={<CalendarToday />}
                    onClick={handleCheckoutPreorder}
                    size="large"
                >
                    Оформить предзаказ
                </Button>
                </Box>

                <CartItemList
                items={preorderItems}
                onQuantityChange={handleQuantityChange}
                onRemove={removeFromCart}
                totalItems={getPreorderCount()}
                totalPrice={preorderTotal}
                showPrice={false} // ← ВЫКЛЮЧАЕМ ЦЕНУ ДЛЯ ПРЕДЗАКАЗА
                />

                <Box sx={{ mt: 2, p: 2, bgcolor: 'warning.light', borderRadius: 1 }}>
                <Typography variant="body2" color="dark">
                    💡 Цена и сроки поставки предзаказа уточняются у менеджера после оформления
                </Typography>
                </Box>
            </Paper>
            )}

        {/* ОБЩИЙ ИТОГ И УПРАВЛЕНИЕ */}
        <Paper elevation={3} sx={{ p: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
            <Typography variant="h5">
              Общий итог
            </Typography>
            <Typography variant="h4" color="primary">
              {totalPrice} ₽
            </Typography>
          </Box>

          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="body2" color="text.secondary">
              {getPurchaseCount() + getPreorderCount()} товаров • {cartItems.length} позиций
            </Typography>
            
            <Box sx={{ display: 'flex', gap: 2 }}>
              {hasPurchase && hasPreorder && (
                <Button
                  variant="contained"
                  size="large"
                  startIcon={<ShoppingCartCheckout />}
                  onClick={handleCheckoutAll}
                  sx={{ py: 1.5 }}
                >
                  Оформить весь заказ
                </Button>
              )}
              
              <Button 
                color="error" 
                onClick={clearCart}
              >
                Очистить корзину
              </Button>
              
              <Button
                variant="outlined"
                onClick={() => navigate('/')}
              >
                Продолжить покупки
              </Button>
            </Box>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
};

export default Cart;