import { API_ENDPOINTS, authFetch, readApiError } from './api';

export const ordersAPI = {
  async list() {
    const response = await authFetch(API_ENDPOINTS.ORDERS);
    if (!response.ok) throw new Error(await readApiError(response, 'Не удалось загрузить заказы'));
    return response.json();
  },

  async create(orderType, items, shippingMethod, shippingAddress) {
    const response = await authFetch(API_ENDPOINTS.ORDERS, {
      method: 'POST',
      body: JSON.stringify({
        order: {
          orderType,
          shipping_method: shippingMethod,
          shipping_address: shippingAddress,
        },
        cards: items.map((item) => ({
          card: item.card.id,
          card_inventory: orderType === 'purchase' ? item.offerId : null,
          quality: item.quality,
          quantity: item.quantity,
        })),
      }),
    });
    if (!response.ok) throw new Error(await readApiError(response, 'Не удалось создать заказ'));
    return response.json();
  },
};
