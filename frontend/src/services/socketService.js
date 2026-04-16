import { io } from "socket.io-client";
import { getApiBaseURL } from "../api/client.js";

let socket = null;

export const connectSocket = (token, userId) => {
  socket = null;
  if (!socket) {
    socket = io(getApiBaseURL(), {
      auth: { token, userId },
    });
  }
  return socket;
};

export const disconnectSocket = () => {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
};

export const getSocket = () => socket;

export const initSocket = (token, userId) => {
  if (token && userId) {
    return connectSocket(token, userId);
  }
  return null;
};
