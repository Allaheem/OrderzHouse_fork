import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { HelmetProvider } from "react-helmet-async";
import App from "./App.jsx";
import "./index.css";
import { Provider } from "react-redux";
import { store } from "./store/store";
import { BrowserRouter } from "react-router-dom";
import { GoogleOAuthProvider } from "@react-oauth/google";
import { ToastProvider } from "./components/toast/ToastProvider.jsx";
import ErrorBoundary from "./components/ErrorBoundary.jsx";

const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;

if (!googleClientId) {
  console.warn("VITE_GOOGLE_CLIENT_ID is not set. Google login will be unavailable.");
}

window.addEventListener("unhandledrejection", (event) => {
  console.error("Unhandled promise rejection:", event.reason);
});

createRoot(document.getElementById("root")).render(
  <ErrorBoundary>
    <HelmetProvider>
      <GoogleOAuthProvider clientId={googleClientId || ""}>
        <BrowserRouter>
          <Provider store={store}>
            <StrictMode>
              <ToastProvider>
                <App />
              </ToastProvider>
            </StrictMode>
          </Provider>
        </BrowserRouter>
      </GoogleOAuthProvider>
    </HelmetProvider>
  </ErrorBoundary>
);
