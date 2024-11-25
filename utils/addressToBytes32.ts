export const addressToBytes32 = (item: string) => {
  const strippedAddress = item.replace(/^0x/, "");
  // Добавляем нули в начало до 64 символов (32 байта в hex)
  const padded = strippedAddress.padStart(64, "0");
  // Возвращаем адрес с "0x"
  return `0x${padded}`;
};
