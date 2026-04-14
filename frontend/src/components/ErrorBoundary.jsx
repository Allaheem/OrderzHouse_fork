import React from "react";

const PRIMARY = "#C2410C";
const DARK = "#9A3412";

export default class ErrorBoundary extends React.Component {
  state = { hasError: false, errorMessage: null };

  static getDerivedStateFromError(error) {
    return { hasError: true, errorMessage: error?.message ?? "Unknown error" };
  }

  componentDidCatch(error, errorInfo) {
    console.error("ErrorBoundary caught an error:", error, errorInfo);
  }

  handleReload = () => {
    window.location.reload();
  };

  handleGoHome = () => {
    window.location.href = "/";
  };

  render() {
    if (this.state.hasError) {
      return (
        <div
          style={{
            minHeight: "100vh",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            padding: "2rem",
            background: "linear-gradient(to bottom, #fff8f5, #ffefe8)",
            fontFamily: "system-ui, sans-serif",
          }}
        >
          <h1
            style={{
              fontSize: "1.5rem",
              fontWeight: 700,
              color: DARK,
              marginBottom: "0.5rem",
            }}
          >
            Something went wrong
          </h1>
          <p
            style={{
              fontSize: "0.875rem",
              color: "#64748b",
              marginBottom: "0.75rem",
            }}
          >
            Try refreshing the page
          </p>
          {this.state.errorMessage ? (
            <pre
              style={{
                maxWidth: "min(100%, 36rem)",
                marginBottom: "1.25rem",
                padding: "0.75rem 1rem",
                fontSize: "0.75rem",
                lineHeight: 1.4,
                color: "#334155",
                background: "#fff",
                border: "1px solid #e2e8f0",
                borderRadius: "0.5rem",
                overflow: "auto",
                textAlign: "left",
                whiteSpace: "pre-wrap",
                wordBreak: "break-word",
              }}
            >
              {this.state.errorMessage}
            </pre>
          ) : null}
          <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap" }}>
            <button
              type="button"
              onClick={this.handleReload}
              style={{
                padding: "0.5rem 1rem",
                fontSize: "0.875rem",
                fontWeight: 600,
                color: "white",
                background: PRIMARY,
                border: "none",
                borderRadius: "0.5rem",
                cursor: "pointer",
              }}
            >
              Reload
            </button>
            <button
              type="button"
              onClick={this.handleGoHome}
              style={{
                padding: "0.5rem 1rem",
                fontSize: "0.875rem",
                fontWeight: 600,
                color: PRIMARY,
                background: "white",
                border: `2px solid ${PRIMARY}`,
                borderRadius: "0.5rem",
                cursor: "pointer",
              }}
            >
              Go Home
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
