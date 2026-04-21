<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Laptop Deployment Checklist</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://alcdn.msauth.net/browser/2.30.0/ms-browser-client-4.4.1.js"></script>
    <link
      href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500;600&family=Space+Grotesk:wght@400;500;600&display=swap"
      rel="stylesheet"
    />
    <style>
      :root {
        /* Base backgrounds (slightly warmed to match palette) */
        --bg: #121414;
        --surface: #1e2326;
        --surface-alt: #2a3034;

        /* Borders */
        --border: #3a3f42;
        --border-light: #4a5054;

        /* Text */
        --text: #e6e6e3;
        --text-muted: #a1a1a1;
        --text-faint: #6f6f6f;

        /* New main palette roles */
        --accent: #99ae48; /* primary (green) */
        --accent-dark: #7f913a;
        --accent-light: #b7c76a;

        --secondary: #608ca5; /* cool contrast (blue) */
        --secondary-light: #7aa6bf;
        --secondary-dark: #4e7488;

        --neutral-accent: #564d48; /* earthy anchor */

        /* Semantic colors (tuned to match palette) */
        --success: #99ae48;
        --danger: #d65c5c;
        --danger-bg: rgba(214, 92, 92, 0.1);
        --danger-border: rgba(214, 92, 92, 0.3);
        --warning: #d4a373;

        /* Info uses the blue now */
        --info-bg: rgba(96, 140, 165, 0.12);
        --info-border: rgba(96, 140, 165, 0.35);

        /* Typography & layout */
        --mono: "Fira Code", monospace;
        --sans: "Space Grotesk", sans-serif;
        --radius: 8px;
        --radius-lg: 12px;
      }

      * {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
      }
      body {
        font-family: var(--sans);
        background: var(--bg);
        color: var(--text);
        min-height: 100vh;
        font-size: 14px;
        line-height: 1.6;
        overflow-x: hidden;
      }

      .app {
        display: flex;
        min-height: 100vh;
      }

      /* Sidebar */
      .sidebar {
        width: 300px;
        min-width: 300px;
        background: linear-gradient(
          180deg,
          var(--surface) 0%,
          var(--surface-alt) 100%
        );
        border-right: 1px solid var(--border);
        display: flex;
        flex-direction: column;
        height: 100vh;
        position: sticky;
        top: 0;
        overflow: hidden;
        box-shadow: 2px 0 8px rgba(0, 0, 0, 0.3);
      }

      .sidebar-header {
        padding: 24px 18px;
        border-bottom: 1px solid var(--border);
        background: var(--surface);
      }

      .sidebar-header h1 {
        font-family: var(--mono);
        font-size: 12px;
        font-weight: 600;
        letter-spacing: 0.1em;
        text-transform: uppercase;
        color: var(--accent);
        margin-bottom: 14px;
        display: flex;
        align-items: center;
        gap: 8px;
      }

      .sidebar-header h1::before {
        content: "⚙️";
        font-size: 16px;
      }

      .new-hire-btn {
        width: 100%;
        background: linear-gradient(
          135deg,
          var(--accent) 0%,
          var(--accent-light) 100%
        );
        color: var(--bg);
        border: none;
        border-radius: var(--radius);
        padding: 10px 12px;
        font-family: var(--sans);
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
        transition: all 0.2s;
        box-shadow: 0 4px 12px rgba(0, 217, 255, 0.2);
      }

      .new-hire-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 16px rgba(0, 217, 255, 0.3);
      }

      .new-hire-btn:active {
        transform: translateY(0);
      }

      .hire-list {
        flex: 1;
        overflow-y: auto;
        padding: 8px 10px;
      }

      .hire-item {
        display: flex;
        align-items: center;
        border-radius: var(--radius);
        margin-bottom: 4px;
        cursor: pointer;
        transition: all 0.15s;
        overflow: hidden;
        position: relative;
        min-width: 0;
      }

      .hire-item:hover {
        background: var(--surface-alt);
      }

      .hire-item.active {
        background: var(--info-bg);
        border-left: 3px solid var(--accent);
        padding-left: 7px;
      }

      .hire-item-inner {
        flex: 1;
        padding: 10px 12px;
        min-width: 0;
        overflow: hidden;
      }

      .hire-name {
        font-size: 13px;
        font-weight: 600;
        color: var(--text);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .hire-item.active .hire-name {
        color: var(--accent);
      }

      .hire-meta {
        font-size: 11px;
        color: var(--text-faint);
        font-family: var(--mono);
        margin-top: 4px;
        line-height: 1.6;
      }

      .meta-line {
        font-size: 11px;
        color: var(--text-faint);
        margin: 1px 0;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .hire-progress-bar {
        height: 4px;
        background: var(--border);
        border-radius: 2px;
        margin-top: 6px;
        overflow: hidden;
      }

      .hire-progress-fill {
        height: 4px;
        background: linear-gradient(90deg, var(--accent), var(--accent-light));
        border-radius: 2px;
        transition: width 0.3s ease;
      }

      .hire-del {
        padding: 6px 8px;
        background: transparent;
        border: none;
        cursor: pointer;
        color: var(--text-faint);
        font-size: 14px;
        border-radius: var(--radius);
        opacity: 0;
        transition: all 0.15s;
        flex-shrink: 0;
      }

      .hire-item:hover .hire-del {
        opacity: 1;
      }

      .hire-del:hover {
        color: var(--danger);
        background: var(--danger-bg);
      }

      .empty-state {
        text-align: center;
        padding: 32px 16px;
        color: var(--text-faint);
        font-size: 12px;
        line-height: 1.8;
      }

      .sidebar-footer {
        padding: 12px 18px;
        border-top: 1px solid var(--border);
        display: flex;
        gap: 8px;
      }

      .entra-btn {
        flex: 1;
        background: var(--surface);
        color: var(--text-muted);
        border: 1px solid var(--border-light);
        border-radius: var(--radius);
        padding: 8px 12px;
        font-family: var(--sans);
        font-size: 11px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
        text-transform: uppercase;
        letter-spacing: 0.05em;
      }

      .entra-btn:hover {
        background: var(--border-light);
        border-color: var(--secondary);
        color: var(--secondary);
      }

      .entra-btn.signed-in {
        background: rgba(96, 140, 165, 0.15);
        border-color: var(--secondary);
        color: var(--secondary);
      }

      .search-modal-overlay {
        display: none;
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.7);
        z-index: 100;
        align-items: center;
        justify-content: center;
        backdrop-filter: blur(2px);
      }

      .search-modal-overlay.open {
        display: flex;
      }

      .search-modal {
        background: var(--surface-alt);
        border: 1px solid var(--border-light);
        border-radius: var(--radius-lg);
        padding: 28px;
        width: 550px;
        max-width: 95vw;
        box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
        max-height: 90vh;
        overflow-y: auto;
        display: flex;
        flex-direction: column;
      }

      .search-modal h2 {
        font-size: 18px;
        font-weight: 700;
        margin-bottom: 4px;
        color: var(--secondary);
      }

      .search-modal-subtitle {
        font-size: 12px;
        color: var(--text-faint);
        margin-bottom: 20px;
        font-family: var(--mono);
      }

      .search-box {
        display: flex;
        gap: 8px;
        margin-bottom: 16px;
      }

      .search-box input {
        flex: 1;
        border: 1px solid var(--border);
        border-radius: var(--radius);
        padding: 10px 12px;
        font-family: var(--sans);
        font-size: 13px;
        color: var(--text);
        background: var(--surface);
        outline: none;
        transition: all 0.2s;
      }

      .search-box input:focus {
        border-color: var(--secondary);
        box-shadow: 0 0 0 3px rgba(96, 140, 165, 0.1);
      }

      .search-box button {
        background: var(--secondary);
        color: white;
        border: none;
        border-radius: var(--radius);
        padding: 10px 16px;
        font-family: var(--sans);
        font-size: 12px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
      }

      .search-box button:hover {
        opacity: 0.9;
      }

      .search-results {
        flex: 1;
        overflow-y: auto;
        margin-bottom: 16px;
        border: 1px solid var(--border);
        border-radius: var(--radius);
        background: var(--surface);
      }

      .search-result-item {
        padding: 12px 14px;
        border-bottom: 1px solid var(--border);
        cursor: pointer;
        transition: all 0.15s;
      }

      .search-result-item:last-child {
        border-bottom: none;
      }

      .search-result-item:hover {
        background: var(--surface-alt);
      }

      .search-result-name {
        font-weight: 600;
        color: var(--text);
        font-size: 13px;
      }

      .search-result-meta {
        font-size: 11px;
        color: var(--text-faint);
        margin-top: 2px;
        font-family: var(--mono);
      }

      .search-loading {
        padding: 20px;
        text-align: center;
        color: var(--text-faint);
      }

      .search-empty {
        padding: 20px;
        text-align: center;
        color: var(--text-faint);
        font-size: 12px;
      }

      .search-modal-actions {
        display: flex;
        justify-content: flex-end;
        gap: 8px;
      }

      /* Main */
      .main {
        flex: 1;
        overflow-y: auto;
        padding: 32px 40px;
        max-width: 900px;
      }

      .no-hire {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 60vh;
        color: var(--text-faint);
        text-align: center;
        gap: 12px;
      }

      .no-hire .icon {
        font-size: 56px;
        margin-bottom: 12px;
        animation: float 3s ease-in-out infinite;
      }

      @keyframes float {
        0%,
        100% {
          transform: translateY(0px);
        }
        50% {
          transform: translateY(-10px);
        }
      }

      .no-hire h2 {
        font-size: 18px;
        font-weight: 600;
        color: var(--text-muted);
      }

      .no-hire p {
        font-size: 13px;
        color: var(--text-faint);
      }

      .hire-header {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        margin-bottom: 28px;
        gap: 16px;
      }

      .hire-title-wrap {
        flex: 1;
      }

      .hire-title {
        font-size: 28px;
        font-weight: 700;
        color: var(--accent);
        margin-bottom: 6px;
      }

      .hire-subtitle {
        font-size: 13px;
        color: var(--text-muted);
        font-family: var(--mono);
      }

      .header-actions {
        display: flex;
        gap: 8px;
        align-items: center;
        flex-wrap: wrap;
      }

      .btn {
        border: 1px solid var(--border-light);
        background: var(--surface-alt);
        color: var(--text-muted);
        border-radius: var(--radius);
        padding: 8px 14px;
        font-family: var(--sans);
        font-size: 12px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
        text-transform: uppercase;
        letter-spacing: 0.05em;
      }

      .btn:hover {
        background: var(--border-light);
        border-color: var(--accent);
        color: var(--accent);
      }

      .btn.danger:hover {
        background: var(--danger-bg);
        border-color: var(--danger);
        color: var(--danger);
      }

      .btn.export {
        background: linear-gradient(135deg, var(--success) 0%, #059669 100%);
        border: none;
        color: white;
      }

      .btn.export:hover {
        background: linear-gradient(135deg, #10b981 0%, #047857 100%);
      }

      .progress-card {
        background: linear-gradient(
          135deg,
          var(--surface) 0%,
          var(--surface-alt) 100%
        );
        border: 1px solid var(--border-light);
        border-radius: var(--radius-lg);
        padding: 20px;
        margin-bottom: 24px;
        display: flex;
        align-items: center;
        gap: 24px;
        box-shadow: 0 4px 12px rgba(0, 217, 255, 0.05);
      }

      .progress-stats {
        flex: 1;
      }

      svg.ring {
        display: block;
        filter: drop-shadow(0 2px 4px rgba(0, 217, 255, 0.1));
      }

      .progress-fraction {
        font-family: var(--mono);
        font-size: 28px;
        font-weight: 700;
        color: var(--accent);
      }

      .progress-label {
        font-size: 12px;
        color: var(--text-faint);
        margin-top: 2px;
      }

      .phase-pills {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
        margin-top: 12px;
      }

      .phase-pill {
        font-size: 10px;
        font-family: var(--mono);
        border-radius: 4px;
        padding: 4px 10px;
        border: 1px solid var(--border);
        color: var(--text-faint);
        background: transparent;
      }

      .phase-pill.done {
        background: rgba(16, 185, 129, 0.1);
        border-color: var(--success);
        color: var(--success);
      }

      .section {
        background: var(--surface-alt);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        margin-bottom: 12px;
        overflow: hidden;
        transition: all 0.2s;
      }

      .section:hover {
        border-color: var(--border-light);
        box-shadow: 0 2px 8px rgba(0, 217, 255, 0.08);
      }

      .section-header {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 14px 16px;
        cursor: pointer;
        user-select: none;
        border-bottom: 1px solid transparent;
        transition: all 0.1s;
      }

      .section-header:hover {
        background: var(--surface);
      }

      .section.open .section-header {
        border-bottom-color: var(--border);
      }

      .section-num {
        font-family: var(--mono);
        font-size: 12px;
        font-weight: 700;
        color: var(--accent);
        width: 24px;
        display: flex;
        align-items: center;
        justify-content: center;
      }

      .section-title {
        font-size: 14px;
        font-weight: 600;
        color: var(--text);
        flex: 1;
      }

      .section-badge {
        font-family: var(--mono);
        font-size: 11px;
        padding: 3px 10px;
        border-radius: 4px;
        background: var(--surface);
        color: var(--text-muted);
        border: 1px solid var(--border);
      }

      .section-badge.done {
        background: rgba(16, 185, 129, 0.1);
        color: var(--success);
        border-color: var(--success);
      }

      .chevron {
        font-size: 10px;
        color: var(--text-faint);
        transition: transform 0.2s;
      }

      .section.open .chevron {
        transform: rotate(90deg);
      }

      .section-body {
        display: none;
      }

      .section.open .section-body {
        display: block;
      }

      .check-item {
        display: flex;
        align-items: flex-start;
        gap: 12px;
        padding: 11px 16px 11px 48px;
        border-bottom: 1px solid var(--border);
        cursor: pointer;
        transition: all 0.1s;
      }

      .check-item:last-child {
        border-bottom: none;
      }

      .check-item:hover {
        background: var(--surface);
      }

      .check-item input[type="checkbox"] {
        margin-top: 2px;
        width: 16px;
        height: 16px;
        cursor: pointer;
        accent-color: var(--accent);
        flex-shrink: 0;
      }

      .check-text {
        flex: 1;
      }

      .check-label {
        font-size: 13px;
        color: var(--text);
        line-height: 1.5;
      }

      .check-label.done {
        text-decoration: line-through;
        color: var(--text-faint);
      }

      .check-note {
        font-size: 11px;
        color: var(--text-faint);
        font-family: var(--mono);
        margin-top: 3px;
        line-height: 1.5;
      }

      .notes-section {
        background: var(--surface-alt);
        border: 1px solid var(--border);
        border-radius: var(--radius-lg);
        margin-top: 24px;
        overflow: hidden;
      }

      .notes-header {
        padding: 14px 16px;
        border-bottom: 1px solid var(--border);
        font-size: 13px;
        font-weight: 600;
        color: var(--accent);
        display: flex;
        align-items: center;
        gap: 8px;
      }

      .notes-header span {
        font-family: var(--mono);
        font-size: 11px;
        color: var(--text-faint);
      }

      textarea.notes {
        width: 100%;
        border: none;
        outline: none;
        resize: vertical;
        font-family: var(--mono);
        font-size: 12px;
        color: var(--text);
        background: var(--surface-alt);
        padding: 14px 16px;
        min-height: 100px;
        line-height: 1.6;
        transition: all 0.2s;
      }

      textarea.notes:focus {
        background: var(--surface);
        outline: 1px solid var(--accent);
      }

      .complete-banner {
        background: linear-gradient(
          135deg,
          rgba(16, 185, 129, 0.1) 0%,
          rgba(16, 185, 129, 0.05) 100%
        );
        border: 1px solid var(--success);
        border-radius: var(--radius);
        padding: 12px 16px;
        font-size: 13px;
        color: var(--success);
        margin-bottom: 20px;
        display: flex;
        align-items: center;
        gap: 10px;
        font-weight: 600;
        box-shadow: 0 2px 8px rgba(16, 185, 129, 0.1);
      }

      /* Modal */
      .modal-overlay {
        display: none;
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.7);
        z-index: 100;
        align-items: center;
        justify-content: center;
        backdrop-filter: blur(2px);
      }

      .modal-overlay.open {
        display: flex;
      }

      .modal {
        background: var(--surface-alt);
        border: 1px solid var(--border-light);
        border-radius: var(--radius-lg);
        padding: 28px;
        width: 500px;
        max-width: 95vw;
        box-shadow: 0 20px 40px rgba(0, 0, 0, 0.5);
        max-height: 90vh;
        overflow-y: auto;
      }

      .modal h2 {
        font-size: 18px;
        font-weight: 700;
        margin-bottom: 4px;
        color: var(--accent);
      }

      .modal-subtitle {
        font-size: 12px;
        color: var(--text-faint);
        margin-bottom: 20px;
        font-family: var(--mono);
      }

      .field {
        margin-bottom: 16px;
        display: flex;
        flex-direction: column;
      }

      .field label {
        display: block;
        font-size: 12px;
        font-weight: 600;
        color: var(--accent);
        margin-bottom: 6px;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        font-family: var(--mono);
      }

      .field input,
      .field select {
        width: 100%;
        border: 1px solid var(--border);
        border-radius: var(--radius);
        padding: 10px 12px;
        font-family: var(--sans);
        font-size: 13px;
        color: var(--text);
        background: var(--surface);
        outline: none;
        transition: all 0.2s;
      }

      .field input:focus,
      .field select:focus {
        border-color: var(--accent);
        box-shadow: 0 0 0 3px rgba(0, 217, 255, 0.1);
      }

      input[type="date"] {
        position: relative;
        width: 100%;
        font-family: var(--sans);
      }

      input[type="date"]::-webkit-calendar-picker-indicator {
        filter: invert(1);
        opacity: 0.7;
        transition: 0.2s;
      }

      input[type="date"]:hover::-webkit-calendar-picker-indicator {
        opacity: 1;
      }

      .modal-actions {
        display: flex;
        justify-content: flex-end;
        gap: 8px;
        margin-top: 24px;
      }

      .btn-primary {
        background: linear-gradient(
          135deg,
          var(--accent) 0%,
          var(--accent-light) 100%
        );
        color: var(--bg);
        border: none;
        border-radius: var(--radius);
        padding: 10px 18px;
        font-family: var(--sans);
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
        text-transform: uppercase;
        letter-spacing: 0.05em;
      }

      .btn-primary:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0, 217, 255, 0.3);
      }

      .info-banner {
        background: var(--info-bg);
        border: 1px solid var(--info-border);
        border-radius: var(--radius);
        padding: 12px 14px;
        font-size: 12px;
        color: var(--accent);
        margin-bottom: 16px;
        line-height: 1.6;
      }

      .info-banner strong {
        font-weight: 600;
      }

      @media (max-width: 900px) {
        .sidebar {
          width: 260px;
          min-width: 260px;
        }
        .main {
          padding: 24px 20px;
          max-width: 100%;
        }
        .header-actions {
          gap: 6px;
        }
        .btn {
          padding: 6px 10px;
          font-size: 11px;
        }
      }

      @media (max-width: 768px) {
        .app {
          flex-direction: column;
        }
        .sidebar {
          width: 100%;
          height: auto;
          position: relative;
          border-right: none;
          border-bottom: 1px solid var(--border);
        }
        .sidebar-header {
          padding: 16px;
        }
        .hire-list {
          max-height: 200px;
        }
        .main {
          padding: 20px;
        }
        .hire-header {
          flex-direction: column;
        }
        .header-actions {
          width: 100%;
          justify-content: stretch;
        }
        .btn {
          flex: 1;
        }
      }

      /* Prevent elements from being split across pages */
      .section,
      .progress-card,
      .notes-section {
        page-break-inside: avoid;
        break-inside: avoid;
      }

      /* Optional: keep headers with their content */
      .section-header {
        page-break-after: avoid;
        break-after: avoid;
      }

      /* Print styles */
      @media print {
        .sidebar,
        .header-actions,
        .new-hire-btn {
          display: none;
        }
        .main {
          padding: 0;
          max-width: 100%;
        }
        .section {
          page-break-inside: avoid;
        }
        body {
          background: white;
          color: black;
        }
      }
    </style>
  </head>
  <body>
    <div class="app">
      <aside class="sidebar">
        <div class="sidebar-header">
          <h1>Deployment</h1>
          <button
            class="new-hire-btn"
            id="new-hire-btn"
            onclick="handleNewHireClick()"
          >
            <span>+</span> New Deployment
          </button>
        </div>
        <div class="hire-list" id="hire-list"></div>
        <div class="sidebar-footer">
          <button class="entra-btn" id="entra-btn" onclick="loginWithEntra()">
            Sign In
          </button>
          <button
            class="entra-btn"
            id="search-user-btn"
            onclick="openUserSearchModal()"
            style="display: none"
          >
            Search User
          </button>
        </div>
      </aside>

      <main class="main" id="main">
        <div class="no-hire">
          <div class="icon">💻</div>
          <h2>No deployment selected</h2>
          <p>
            Create a new deployment record to begin<br />the laptop setup and
            configuration checklist.
          </p>
        </div>
      </main>
    </div>

    <!-- New Deployment Modal -->
    <div class="modal-overlay" id="modal">
      <div class="modal">
        <h2>New laptop deployment</h2>
        <p class="modal-subtitle">Fill in employee and device information</p>

        <div class="field">
          <label>Employee Name</label>
          <input
            type="text"
            id="m-name"
            placeholder="Jane Smith"
            autocomplete="off"
          />
        </div>

        <div class="field">
          <label>Department</label>
          <select id="m-dept">
            <option value="">Select Department</option>
            <option value="Executive">Executive</option>
            <option value="Human Resources">Human Resources</option>
            <option value="Marketing">Marketing</option>
            <option value="Finance">Finance</option>
            <option value="Information Technology">
              Information Technology
            </option>
            <option value="Legal">Legal</option>
            <option value="Facilities">Facilities</option>
            <option value="Core">Core</option>
            <option value="Electrical">Electrical</option>
            <option value="Architecture">Architecture</option>
            <option value="Water">Water</option>
            <option value="Environmental">Environmental</option>
            <option value="Civil-Survey">Civil-Survey</option>
            <option value="Inspector Field">Inspector Field</option>
          </select>
        </div>

        <div class="field">
          <label>Employee Email</label>
          <input
            type="text"
            id="m-email"
            placeholder="JDoe@H2M.com"
            autocomplete="off"
          />
        </div>

        <div class="field">
          <label>Office Location</label>
          <select id="m-office">
            <option value="">Select Office</option>
            <option value="Melville">Melville</option>
            <option value="Parsippany">Parsippany</option>
            <option value="NYC">NYC</option>
            <option value="Suffern">Suffern</option>
            <option value="Troy">Troy</option>
            <option value="Boca">Boca</option>
            <option value="Wall">Wall (Central New Jersey)</option>
            <option value="Westchester">Westchester</option>
            <option value="Windsor">Windsor</option>
          </select>
        </div>

        <div class="field">
          <label>PC Name</label>
          <input
            type="text"
            id="m-pc-name"
            placeholder="DEV-001"
            autocomplete="off"
          />
        </div>

        <div class="field">
          <label>Employee Type</label>
          <select id="m-emp-type">
            <option value="">Select Type</option>
            <option value="New Hire">New Hire</option>
            <option value="Existing Employee">Existing Employee</option>
          </select>
        </div>

        <div class="field" id="start-date-field">
          <label>Start Date</label>
          <input type="date" id="m-start" />
        </div>

        <div class="field">
          <label>Device Type</label>
          <select id="m-device-type">
            <option value="">Select Type</option>
            <option value="New">New</option>
            <option value="Redeployment">Redeployment</option>
            <option value="Intern">Intern</option>
            <option value="Rendering">Rendering</option>
            <option value="Wipe/Reset">Wipe/Reset</option>
          </select>
        </div>

        <div class="modal-actions">
          <button class="btn" onclick="closeModal()">Cancel</button>
          <button class="btn-primary" onclick="createHire()">
            Create Checklist
          </button>
        </div>
      </div>
    </div>

    <!-- User Search Modal -->
    <div class="search-modal-overlay" id="search-modal">
      <div class="search-modal">
        <h2>Search Entra User</h2>
        <p class="search-modal-subtitle">Find user to auto-populate form</p>

        <div class="search-box">
          <input
            type="text"
            id="search-input"
            placeholder="Search by name or email..."
            autocomplete="off"
            onkeyup="if (event.key === 'Enter') searchEntraUsers();"
          />
          <button onclick="searchEntraUsers()">Search</button>
        </div>

        <div class="search-results" id="search-results" style="display: none">
          <div class="search-empty">No results</div>
        </div>

        <div class="search-modal-actions">
          <button class="btn" onclick="closeUserSearchModal()">Close</button>
          <button class="btn-primary" onclick="continueWithoutUser()">
            Continue Without User
          </button>
        </div>
      </div>
    </div>

    <div class="modal-overlay" id="reset-modal">
      <div class="modal">
        <h2>Reset Deployment</h2>
        <p>
          Are you sure you want to reset all checkboxes for this deployment?
          This action cannot be undone.
        </p>
        <div
          style="
            display: flex;
            gap: 12px;
            margin-top: 24px;
            justify-content: flex-end;
          "
        >
          <button class="btn" onclick="closeResetModal()">Cancel</button>
          <button class="btn danger" onclick="confirmReset()">Reset</button>
        </div>
      </div>
    </div>

    <div class="modal-overlay" id="delete-modal">
      <div class="modal">
        <h2>Delete Deployment</h2>
        <p id="delete-modal-message">
          Are you sure you want to delete this deployment? This action cannot be
          undone.
        </p>
        <div
          style="
            display: flex;
            gap: 12px;
            margin-top: 24px;
            justify-content: flex-end;
          "
        >
          <button class="btn" onclick="closeDeleteModal()">Cancel</button>
          <button class="btn danger" onclick="confirmDelete()">Delete</button>
        </div>
      </div>
    </div>

    <script>
      // ============================================================
      // SETUP INSTRUCTIONS
      // ============================================================
      // 1. Register an Azure AD Application:
      //    - Go to: https://portal.azure.com
      //    - Search for "App registrations" and select it
      //    - Click "+ New registration"
      //    - Name it "H2M Laptop Checklist"
      //    - Select "Accounts in this organizational directory only"
      //    - For Redirect URI: Select "Single-page application (SPA)"
      //      and enter: http://localhost:8000 (or your deployed URL)
      //    - Click "Register"
      //
      // 2. Copy your Client ID (Application ID)
      //    - Go to "Overview" tab
      //    - Copy "Application (client) ID"
      //    - Paste it below in the MSAL config
      //
      // 3. Get your Tenant ID
      //    - Also on "Overview" tab
      //    - Copy "Directory (tenant) ID"
      //    - Paste it below
      //
      // 4. Grant API permissions:
      //    - Click "API permissions" in left menu
      //    - Click "+ Add a permission"
      //    - Select "Microsoft Graph"
      //    - Select "Delegated permissions"
      //    - Search for and add: User.Read, User.ReadBasic.All
      //    - Click "Add permissions"
      //
      // 5. Replace YOUR_CLIENT_ID and YOUR_TENANT_ID below
      //
      // ============================================================
      // MSAL Configuration
      // ============================================================
      const msalConfig = {
        auth: {
          clientId: "YOUR_CLIENT_ID", // Replace with your Application (client) ID
          authority: "https://login.microsoftonline.com/YOUR_TENANT_ID", // Replace with your Directory (tenant) ID
          redirectUri: window.location.origin,
        },
        cache: {
          cacheLocation: "localStorage",
          storeAuthStateInCookie: false,
        },
      };

      const graphScopes = ["user.read", "user.readbasic.all"];
      let msalInstance = null;
      let msalAccount = null;

      // Initialize MSAL
      async function initMsal() {
        msalInstance = new msal.PublicClientApplication(msalConfig);
        try {
          await msalInstance.initialize();
          const accounts = msalInstance.getAllAccounts();
          if (accounts.length > 0) {
            msalAccount = accounts[0];
            updateEntraUI(true);
          }
        } catch (error) {
          console.error("MSAL initialization error:", error);
        }
      }

      function updateEntraUI(isSignedIn) {
        const entraBtn = document.getElementById("entra-btn");
        const searchBtn = document.getElementById("search-user-btn");
        if (isSignedIn) {
          entraBtn.textContent = "Sign Out";
          entraBtn.classList.add("signed-in");
          searchBtn.style.display = "block";
        } else {
          entraBtn.textContent = "Sign In";
          entraBtn.classList.remove("signed-in");
          searchBtn.style.display = "none";
        }
      }

      async function loginWithEntra() {
        if (!msalInstance) await initMsal();

        if (msalAccount) {
          // Sign out
          await msalInstance.logoutPopup();
          msalAccount = null;
          updateEntraUI(false);
        } else {
          // Sign in
          try {
            const result = await msalInstance.loginPopup({
              scopes: graphScopes,
            });
            msalAccount = result.account;
            updateEntraUI(true);
          } catch (error) {
            console.error("Login error:", error);
            alert("Failed to sign in. Check console for details.");
          }
        }
      }

      async function searchEntraUsers() {
        if (!msalAccount) {
          alert("Please sign in first");
          return;
        }

        const searchTerm = document.getElementById("search-input").value.trim();
        if (!searchTerm) {
          alert("Enter a name or email to search");
          return;
        }

        const resultsDiv = document.getElementById("search-results");
        resultsDiv.innerHTML = '<div class="search-loading">Searching...</div>';
        resultsDiv.style.display = "block";

        try {
          const token = await msalInstance.acquireTokenSilent({
            scopes: graphScopes,
            account: msalAccount,
          });
          const response = await fetch(
            `https://graph.microsoft.com/v1.0/users?$filter=startswith(displayName,'${searchTerm}') or startswith(userPrincipalName,'${searchTerm}') or startswith(mail,'${searchTerm}')&$select=id,displayName,mail,department,officeLocation,jobTitle,mobilePhone,telephoneNumber,employeeId,companyName`,
            { headers: { Authorization: `Bearer ${token.accessToken}` } },
          );

          if (!response.ok) throw new Error("Search failed");
          const data = await response.json();

          if (data.value.length === 0) {
            resultsDiv.innerHTML =
              '<div class="search-empty">No users found</div>';
          } else {
            resultsDiv.innerHTML = data.value
              .map(
                (user) => `
              <div class="search-result-item" onclick="selectEntraUser(${JSON.stringify(user).replace(/"/g, "&quot;")})">
                <div class="search-result-name">${esc(user.displayName)}</div>
                <div class="search-result-meta">${esc(user.mail || "")} • ${esc(user.jobTitle || "")}</div>
              </div>
            `,
              )
              .join("");
          }
        } catch (error) {
          console.error("Search error:", error);
          resultsDiv.innerHTML = `<div class="search-empty">Error: ${error.message}</div>`;
        }
      }

      function selectEntraUser(user) {
        // Map Entra fields to form fields
        document.getElementById("m-name").value = user.displayName || "";
        document.getElementById("m-email").value = user.mail || "";
        document.getElementById("m-pc-name").value = user.employeeId
          ? `${user.employeeId}-`
          : "";

        // Set department dropdown if it matches
        const deptSelect = document.getElementById("m-dept");
        if (user.department) {
          for (let opt of deptSelect.options) {
            if (opt.value.toLowerCase() === user.department.toLowerCase()) {
              deptSelect.value = opt.value;
              break;
            }
          }
        }

        // Set office dropdown if it matches
        const officeSelect = document.getElementById("m-office");
        if (user.officeLocation) {
          for (let opt of officeSelect.options) {
            if (
              opt.value
                .toLowerCase()
                .includes(user.officeLocation.toLowerCase()) ||
              user.officeLocation
                .toLowerCase()
                .includes(opt.value.toLowerCase())
            ) {
              officeSelect.value = opt.value;
              break;
            }
          }
        }

        closeUserSearchModal();
      }

      function openUserSearchModal() {
        document.getElementById("search-modal").classList.add("open");
        document.getElementById("search-input").value = "";
        document.getElementById("search-results").style.display = "none";
        setTimeout(() => document.getElementById("search-input").focus(), 80);
      }

      function closeUserSearchModal() {
        document.getElementById("search-modal").classList.remove("open");
      }

      function continueWithoutUser() {
        closeUserSearchModal();
        openNewHireModal();
      }

      document
        .getElementById("search-modal")
        .addEventListener("click", function (e) {
          if (e.target === this) closeUserSearchModal();
        });
      // ============================================================
      // Checklist Sections Data
      // ============================================================
      const SECTIONS = [
        {
          title: "New Account Setup",
          items: [
            { text: "Create User AD account", note: "" },
            { text: "Enable Microsoft Exchange Mailbox settings", note: "" },
            { text: "Assign DID in RingCentral Admin Console", note: "" },
          ],
        },
        {
          title: "Pre-Device Setup",
          items: [
            { text: "Helpdesk Ticket Created", note: "" },
            { text: "Set Temporary Password", note: "Reset After Setup" },
          ],
        },
        {
          title: "Device Setup",
          items: [
            { text: "Assign PC Name", note: "" },
            { text: "Move Device to Correct OU", note: "" },
            { text: "Log into OneDrive", note: "" },
          ],
        },
        {
          title: "Intune Application Verification",
          items: [
            { text: "Splashtop", note: "" },
            { text: "Newforma", note: "" },
            { text: "BST11", note: "" },
            { text: "Cisco VPN - Remove from startup app", note: "" },
            { text: "Microsoft Edge", note: "" },
            { text: "CrowdStrike", note: "" },
            { text: "RingCentral", note: "" },
            { text: "Dell Command Update", note: "" },
            { text: "DNSfilter", note: "" },
            {
              text: "Acrobat Reader / Acrobat Standard / Bluebeam Core",
              note: "",
            },
          ],
        },
        {
          title: "Device Configuration",
          items: [
            { text: "Install and Set Default Printers", note: "" },
            {
              text: "Set Taskbar (Edge, File Explorer, Outlook, Teams, BST11)",
              note: "",
            },
            { text: "Set Up Outlook", note: "" },
            { text: "Install Windows Updates", note: "" },
            { text: "Set Up Newforma", note: "" },
            { text: "Install Dell Command Updates", note: "" },
            { text: "Register Adobe/Bluebeam", note: "" },
            { text: "Install Outstanding apps from Helpdesk Ticket", note: "" },
            { text: "Set Taskbar Widgets Settings Off", note: "" },
            { text: "Connect to H2M", note: "" },
          ],
        },
        {
          title: "Post Device Setup",
          items: [
            { text: "Verify Outlook license and accounts", note: "" },
            { text: "Verify Bluebeam license", note: "" },
            { text: "Verify RingCentral", note: "" },
            { text: "Verify Adobe license", note: "" },
            { text: "Verify Teams functionality", note: "" },
            { text: "Dock is fully functional", note: "" },
            { text: "Monitor orientation for local setups", note: "" },
            { text: "Verify all peripherals (Headphones)", note: "" },
          ],
        },
        {
          title: "Computer List Status",
          items: [
            { text: "Deployed", note: "" },
            {
              text: "Add Device to PatchMyPC-Application-Updates-Devices group in Entra",
              note: "",
            },
            {
              text: "Add Device to AutoPatch Phase 2 Group in Entra/Intune",
              note: "",
            },
            {
              text: "Remove Device From Intune-Setup-Devices in Entra",
              note: "",
            },
            {
              text: "*For Structural Devices Only* Add Device to Softrack on mgnt-server",
              note: "",
            },
            {
              text: "*For Non Autopiloted Devices Only* Add Device to Intune-Static-Everybody-Devices group in Entra",
              note: "",
            },
          ],
        },
      ];

      const TOTAL_ITEMS = SECTIONS.reduce((a, s) => a + s.items.length, 0);

      // ============================================================
      // Storage & State
      // ============================================================
      const STORE_KEY = "h2m_deploy_v1";
      let db = {};
      let activeId = null;
      let deleteTargetId = null;

      function load() {
        try {
          db = JSON.parse(localStorage.getItem(STORE_KEY)) || {};
        } catch (e) {
          db = {};
        }
      }

      function save() {
        localStorage.setItem(STORE_KEY, JSON.stringify(db));
      }

      function getChecked(h) {
        // Count only items from visible sections based on employee type
        let count = 0;
        SECTIONS.forEach((sec, si) => {
          // Skip "New Account Setup" for Existing Employees
          if (
            h.empType === "Existing Employee" &&
            sec.title === "New Account Setup"
          ) {
            return;
          }
          sec.items.forEach((_, ii) => {
            if (h.checks?.[`${si}_${ii}`]) {
              count++;
            }
          });
        });
        return count;
      }

      // ============================================================
      // Render Functions
      // ============================================================
      function renderSidebar() {
        const list = document.getElementById("hire-list");
        const keys = Object.keys(db).sort(
          (a, b) => db[b].created - db[a].created,
        );

        if (keys.length === 0) {
          list.innerHTML =
            '<div class="empty-state">No deployments yet.<br>Click <strong>+ New Deployment</strong> to start.</div>';
        } else {
          list.innerHTML = keys
            .map((id) => {
              const h = db[id];
              const done = getChecked(h);

              // Calculate total items based on employee type
              const sidebarVisibleSections =
                h.empType === "Existing Employee"
                  ? SECTIONS.filter((sec) => sec.title !== "New Account Setup")
                  : SECTIONS;
              const sidebarTotalItems = sidebarVisibleSections.reduce(
                (a, s) => a + s.items.length,
                0,
              );

              const pct = Math.round((done / sidebarTotalItems) * 100);
              const active = id === activeId ? " active" : "";
              const metaLines = [
                h.email
                  ? `<div class="meta-line">Email: ${esc(h.email)}</div>`
                  : "",
                h.dept
                  ? `<div class="meta-line">Dept: ${esc(h.dept)}</div>`
                  : "",
                h.empType
                  ? `<div class="meta-line">Type: ${esc(h.empType)}</div>`
                  : "",
                h.deviceType
                  ? `<div class="meta-line">Device: ${esc(h.deviceType)}</div>`
                  : "",
                h.pcName
                  ? `<div class="meta-line">PC: ${esc(h.pcName)}</div>`
                  : "",
                h.office
                  ? `<div class="meta-line">Office: ${esc(h.office)}</div>`
                  : "",
                h.start
                  ? `<div class="meta-line">Start: ${esc(h.start)}</div>`
                  : "",
              ]
                .filter(Boolean)
                .join("");
              return `<div class="hire-item${active}" onclick="selectHire('${id}')">
          <div class="hire-item-inner">
            <div class="hire-name">${esc(h.name)}</div>
            <div class="hire-meta">${metaLines}</div>
            <div class="hire-progress-bar"><div class="hire-progress-fill" style="width:${pct}%"></div></div>
          </div>
          <button class="hire-del" title="Delete" onclick="event.stopPropagation();deleteHire('${id}')">✕</button>
        </div>`;
            })
            .join("");
        }
      }

      function renderMain() {
        const main = document.getElementById("main");
        if (!activeId || !db[activeId]) {
          main.innerHTML = `<div class="no-hire"><div class="icon">💻</div><h2>No deployment selected</h2><p>Select a deployment from the sidebar or create a new one.</p></div>`;
          return;
        }

        const h = db[activeId];
        const done = getChecked(h);

        // Calculate total items based on employee type
        const visibleSections =
          h.empType === "Existing Employee"
            ? SECTIONS.filter((sec) => sec.title !== "New Account Setup")
            : SECTIONS;
        const totalItems = visibleSections.reduce(
          (a, s) => a + s.items.length,
          0,
        );

        const pct = Math.round((done / totalItems) * 100);
        const isComplete = done === totalItems || h.forceComplete;

        const sectionPills = SECTIONS.map((s, si) => {
          // Skip "New Account Setup" for Existing Employees
          if (
            h.empType === "Existing Employee" &&
            s.title === "New Account Setup"
          ) {
            return "";
          }
          const secDone = s.items.filter(
            (_, ii) => h.checks?.[`${si}_${ii}`],
          ).length;
          return `<span class="phase-pill${secDone === s.items.length ? " done" : ""}">${esc(s.title)}</span>`;
        }).join("");

        const completeBanner = isComplete
          ? `<div class="complete-banner">✓ Deployment complete -- laptop ready for ${esc(h.name)}</div>`
          : "";

        // Create array of visible sections with their original indices
        const visibleSectionsWithIndices = SECTIONS.map((sec, originalSi) => ({
          sec,
          originalSi,
        })).filter(
          ({ sec }) =>
            !(
              h.empType === "Existing Employee" &&
              sec.title === "New Account Setup"
            ),
        );

        const sectionsHtml = visibleSectionsWithIndices
          .map(({ sec, originalSi }, displayIndex) => {
            const secDone = sec.items.filter(
              (_, ii) => h.checks?.[`${originalSi}_${ii}`],
            ).length;
            const allDone = secDone === sec.items.length;
            const isOpen = h.open?.[originalSi] !== false;
            const itemsHtml = sec.items
              .map((item, ii) => {
                const key = `${originalSi}_${ii}`;
                const checked = !!h.checks?.[key];
                return `<div class="check-item" onclick="toggleItem('${originalSi}','${ii}')">
            <input type="checkbox" ${checked ? "checked" : ""} onclick="event.stopPropagation();toggleItem('${originalSi}','${ii}')">
            <div class="check-text">
              <div class="check-label${checked ? " done" : ""}">${esc(item.text)}</div>
              ${item.note ? `<div class="check-note">${esc(item.note)}</div>` : ""}
            </div>
          </div>`;
              })
              .join("");
            return `<div class="section${isOpen ? " open" : ""}" id="sec-${originalSi}">
          <div class="section-header" onclick="toggleSection(${originalSi})">
            <span class="section-num">0${displayIndex + 1}</span>
            <span class="section-title">${esc(sec.title)}</span>
            <span class="section-badge${allDone ? " done" : ""}">${secDone}/${sec.items.length}</span>
            <span class="chevron">►</span>
          </div>
          <div class="section-body">${itemsHtml}</div>
        </div>`;
          })
          .join("");

        const subLine = [h.empType, h.department].filter(Boolean).join(" • ");
        const metaLine = [
          h.pcName,
          h.office ? "Office: " + h.office : "",
          h.start ? "Start: " + h.start : "",
        ]
          .filter(Boolean)
          .join(" • ");
        const r = 26,
          cx = 30,
          cy = 30,
          circ = 2 * Math.PI * r;
        const dash = (pct / 100) * circ;

        main.innerHTML = `
      <div class="hire-header">
        <div class="hire-title-wrap">
          <div class="hire-title">${esc(h.name)}</div>
          ${h.email ? `<div class="hire-subtitle">${esc(h.email)}</div>` : ""}
          ${subLine ? `<div class="hire-subtitle">${esc(subLine)}</div>` : ""}
          ${metaLine ? `<div class="hire-subtitle" style="margin-top:3px;font-size:11px;font-weight:500">${metaLine}</div>` : ""}
        </div>
        <div class="header-actions">
          <button class="btn export" onclick="exportPDF()">📄 Export PDF</button>
          <button class="btn" onclick="checkAllBoxes()">✓ Check All</button>
          <button class="btn" onclick="forceComplete()">⚡ ${h.forceComplete ? "Unforce Complete" : "Force Complete"}</button>
          <button class="btn" onclick="resetHire()">Reset</button>
          <button class="btn danger" onclick="deleteHire('${activeId}')">Delete</button>
        </div>
      </div>
      ${completeBanner}
      <div class="progress-card">
        <div>
          <svg class="ring" width="60" height="60" viewBox="0 0 60 60">
            <circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="#2C3D54" stroke-width="5"/>
            <circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="#00D9FF" stroke-width="5"
              stroke-dasharray="${dash.toFixed(1)} ${circ.toFixed(1)}"
              stroke-linecap="round" transform="rotate(-90 ${cx} ${cy})"/>
          </svg>
        </div>
        <div class="progress-stats">
          <div class="progress-fraction">${done}<span style="font-size:16px;color:var(--text-faint)"> / ${totalItems}</span></div>
          <div class="progress-label">${pct}% complete</div>
          <div class="phase-pills">${sectionPills}</div>
        </div>
      </div>
      ${sectionsHtml}
      <div class="notes-section">
        <div class="notes-header">Deployment Notes <span>// log any issues here</span></div>
        <textarea class="notes" placeholder="Serial number, issues encountered, special configurations..." oninput="saveNotes(this.value)">${esc(h.notes || "")}</textarea>
      </div>`;
      }

      function selectHire(id) {
        activeId = id;
        renderSidebar();
        renderMain();
      }

      function toggleItem(si, ii) {
        if (!activeId) return;
        const key = `${si}_${ii}`;
        const h = db[activeId];
        if (!h.checks) h.checks = {};
        h.checks[key] = !h.checks[key];
        save();
        renderSidebar();
        renderMain();
      }

      function toggleSection(si) {
        if (!activeId) return;
        const h = db[activeId];
        if (!h.open) h.open = {};
        h.open[si] = h.open[si] === false ? true : false;
        save();
        const sec = document.getElementById("sec-" + si);
        if (sec) sec.classList.toggle("open");
      }

      function saveNotes(val) {
        if (!activeId) return;
        db[activeId].notes = val;
        save();
      }

      function resetHire() {
        if (!activeId) return;
        document.getElementById("reset-modal").classList.add("open");
      }

      function closeResetModal() {
        document.getElementById("reset-modal").classList.remove("open");
      }

      function confirmReset() {
        db[activeId].checks = {};
        db[activeId].forceComplete = false;
        save();
        renderSidebar();
        renderMain();
        closeResetModal();
      }

      function checkAllBoxes() {
        if (!activeId) return;
        const h = db[activeId];
        if (!h.checks) h.checks = {};
        SECTIONS.forEach((sec, si) => {
          sec.items.forEach((_, ii) => {
            h.checks[`${si}_${ii}`] = true;
          });
        });
        h.forceComplete = false;
        save();
        renderSidebar();
        renderMain();
      }

      function forceComplete() {
        if (!activeId) return;
        const h = db[activeId];
        h.forceComplete = !h.forceComplete;
        save();
        renderSidebar();
        renderMain();
      }

      function deleteHire(id) {
        if (!db[id]) return;
        deleteTargetId = id;
        document.getElementById("delete-modal-message").textContent =
          `Delete checklist for ${db[id].name}? This cannot be undone.`;
        document.getElementById("delete-modal").classList.add("open");
      }

      function closeDeleteModal() {
        document.getElementById("delete-modal").classList.remove("open");
        deleteTargetId = null;
      }

      function confirmDelete() {
        if (!deleteTargetId) return;
        delete db[deleteTargetId];
        if (activeId === deleteTargetId) activeId = null;
        save();
        renderSidebar();
        renderMain();
        closeDeleteModal();
      }

      // ============================================================
      // Export Functions (jsPDF - Text-Based - Professional)
      // ============================================================
      async function exportPDF() {
        if (!activeId) return;
        const h = db[activeId];
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF({
          orientation: "portrait",
          unit: "mm",
          format: "a4",
        });

        // Load and add logo
        try {
          const logoUrl =
            "https://www.h2m.com/wp-content/uploads/2023/01/H2M-90-Years-white.png";
          const response = await fetch(logoUrl);
          const blob = await response.blob();
          const logoData = await new Promise((resolve) => {
            const reader = new FileReader();
            reader.onloadend = () => resolve(reader.result);
            reader.readAsDataURL(blob);
          });
          doc.addImage(logoData, "PNG", 12, 8, 35, 12); // x, y, width, height
        } catch (e) {
          console.warn("Could not load logo:", e);
        }

        const pageWidth = doc.internal.pageSize.getWidth();
        const pageHeight = doc.internal.pageSize.getHeight();
        let yPos = 28;
        const margin = 12;
        const lineHeight = 5;
        let pageNum = 1;

        // Helper to add text with auto page break
        function addText(text, fontSize = 11, bold = false, indent = 0) {
          doc.setFontSize(fontSize);
          doc.setFont(undefined, bold ? "bold" : "normal");
          const x = margin + indent;
          const maxWidth = pageWidth - 2 * margin - indent;
          const lines = doc.splitTextToSize(text, maxWidth);

          lines.forEach((line) => {
            if (yPos + lineHeight > pageHeight - 15) {
              addPageNumber();
              doc.addPage();
              yPos = 15;
              pageNum++;
            }
            doc.text(line, x, yPos);
            yPos += lineHeight;
          });
        }

        function addLine() {
          doc.setDrawColor(150, 150, 150);
          doc.line(margin, yPos, pageWidth - margin, yPos);
          yPos += 3;
        }

        function addPageNumber() {
          doc.setFontSize(9);
          doc.setFont(undefined, "normal");
          doc.setTextColor(180, 180, 180);
          doc.text(`Page ${pageNum}`, pageWidth - margin - 10, pageHeight - 8);
          doc.setTextColor(0, 0, 0);
        }

        // Title with styling
        doc.setFontSize(16);
        doc.setFont(undefined, "bold");
        doc.text("LAPTOP DEPLOYMENT CHECKLIST", margin, yPos);
        yPos += 8;
        addLine();
        yPos += 2;

        // Employee Info Section
        doc.setFontSize(12);
        doc.setFont(undefined, "bold");
        doc.text("EMPLOYEE INFORMATION", margin, yPos);
        yPos += 6;

        doc.setFontSize(10);
        doc.setFont(undefined, "normal");
        const done = getChecked(h);

        // Calculate total items based on employee type
        const pdfVisibleSections =
          h.empType === "Existing Employee"
            ? SECTIONS.filter((sec) => sec.title !== "New Account Setup")
            : SECTIONS;
        const pdfTotalItems = pdfVisibleSections.reduce(
          (a, s) => a + s.items.length,
          0,
        );
        const progress = Math.round((done / pdfTotalItems) * 100);

        const infoItems = [
          [`Employee Name:`, h.name || "N/A"],
          [`Email:`, h.email || "N/A"],
          [`PC Name:`, h.pcName || "N/A"],
          [`Department:`, h.department || "N/A"],
          [`Type:`, h.empType || "N/A"],
          [`Device Type:`, h.deviceType || "N/A"],
          [`Office:`, h.office || "N/A"],
          [`Start Date:`, h.start || "N/A"],
          [`Progress:`, `${done}/${pdfTotalItems} (${progress}%)`],
        ];

        infoItems.forEach(([label, value]) => {
          doc.setFont(undefined, "bold");
          doc.text(label, margin + 2, yPos);
          doc.setFont(undefined, "normal");
          doc.text(value, margin + 60, yPos);
          yPos += 5;
        });

        yPos += 3;
        addLine();
        yPos += 2;

        // Checklist Sections
        doc.setFontSize(12);
        doc.setFont(undefined, "bold");
        doc.text("DEPLOYMENT CHECKLIST", margin, yPos);
        yPos += 6;

        // Filter sections for Existing Employees
        const pdfSections =
          h.empType === "Existing Employee"
            ? SECTIONS.filter((sec) => sec.title !== "New Account Setup")
            : SECTIONS;

        pdfSections.forEach((sec, displayIndex) => {
          // Find original section index
          const originalIndex = SECTIONS.indexOf(sec);

          // Force page break before section 6 (which is index 5)
          if (originalIndex === 5 && pageNum === 1) {
            addPageNumber();
            doc.addPage();
            yPos = 15;
            pageNum++;
          }

          // Section header
          doc.setFontSize(11);
          doc.setFont(undefined, "bold");
          doc.setFillColor(230, 230, 230);
          doc.rect(margin, yPos - 3.5, pageWidth - 2 * margin, 5.5, "F");
          doc.text(`${displayIndex + 1}. ${sec.title}`, margin + 2, yPos);
          yPos += 7;

          // Section items
          doc.setFontSize(9.5);
          doc.setFont(undefined, "normal");
          sec.items.forEach((item, ii) => {
            // Check if we need a new page before adding item
            if (yPos + 10 > pageHeight - 15) {
              addPageNumber();
              doc.addPage();
              yPos = 15;
              pageNum++;
            }

            const key = `${originalIndex}_${ii}`;
            const isChecked = !!h.checks?.[key];
            const prefix = isChecked ? "[X]" : "[ ]";

            // Add checkbox prefix
            doc.setFont(undefined, isChecked ? "bold" : "normal");
            doc.text(prefix, margin + 2, yPos);

            // Add item text
            const maxWidth = pageWidth - 2 * margin - 12;
            const lines = doc.splitTextToSize(item.text, maxWidth);
            lines.forEach((line, idx) => {
              // Check again if we need another page for wrapped lines
              if (yPos + 4 > pageHeight - 15) {
                addPageNumber();
                doc.addPage();
                yPos = 15;
                pageNum++;
              }
              doc.text(line, margin + 10, yPos);
              yPos += 4;
            });

            // Add note if exists
            if (item.note) {
              doc.setFontSize(8.5);
              doc.setFont(undefined, "italic");
              const noteLines = doc.splitTextToSize(
                `* ${item.note}`,
                maxWidth - 5,
              );
              noteLines.forEach((line) => {
                // Check if we need another page for note lines
                if (yPos + 3.5 > pageHeight - 15) {
                  addPageNumber();
                  doc.addPage();
                  yPos = 15;
                  pageNum++;
                }
                doc.text(line, margin + 13, yPos);
                yPos += 3.5;
              });
              doc.setFontSize(9.5);
            }
          });

          yPos += 2;
        });

        // Notes Section
        if (h.notes) {
          yPos += 2;
          addLine();
          yPos += 2;

          doc.setFontSize(12);
          doc.setFont(undefined, "bold");
          doc.text("DEPLOYMENT NOTES", margin, yPos);
          yPos += 5;

          doc.setFontSize(9.5);
          doc.setFont(undefined, "normal");
          const noteLines = doc.splitTextToSize(
            h.notes,
            pageWidth - 2 * margin,
          );
          noteLines.forEach((line) => {
            if (yPos + 4 > pageHeight - 15) {
              addPageNumber();
              doc.addPage();
              yPos = 15;
              pageNum++;
            }
            doc.text(line, margin, yPos);
            yPos += 4;
          });
        }

        // Footer
        addPageNumber();

        // Save
        const filename = `Setup & Install Checklist - ${h.name.replace(/\s+/g, "-")}_${new Date().toISOString().split("T")[0]}.pdf`;
        doc.save(filename);
      }

      // ============================================================
      // Modal Functions
      // ============================================================
      function openNewHireModal() {
        [
          "m-name",
          "m-email",
          "m-dept",
          "m-office",
          "m-pc-name",
          "m-emp-type",
          "m-start",
          "m-device-type",
        ].forEach((id) => {
          const el = document.getElementById(id);
          if (el.tagName === "INPUT") el.value = "";
          else el.selectedIndex = 0;
        });
        // Show start date field by default
        document.getElementById("start-date-field").style.display = "flex";
        document.getElementById("modal").classList.add("open");
        setTimeout(() => document.getElementById("m-name").focus(), 80);
      }

      function handleNewHireClick() {
        if (msalAccount) {
          openUserSearchModal();
        } else {
          openNewHireModal();
        }
      }

      function closeModal() {
        document.getElementById("modal").classList.remove("open");
      }

      function createHire() {
        const name = document.getElementById("m-name").value.trim();
        if (!name) {
          alert("Please enter an employee name.");
          return;
        }

        const id = "h" + Date.now() + Math.random().toString(36).slice(2, 6);
        db[id] = {
          name,
          email: document.getElementById("m-email").value.trim(),
          department: document.getElementById("m-dept").value.trim(),
          office: document.getElementById("m-office").value.trim(),
          pcName: document.getElementById("m-pc-name").value.trim(),
          empType: document.getElementById("m-emp-type").value.trim(),
          start: document.getElementById("m-start").value,
          deviceType: document.getElementById("m-device-type").value.trim(),
          checks: {},
          open: {},
          notes: "",
          created: Date.now(),
        };
        save();
        activeId = id;
        closeModal();
        renderSidebar();
        renderMain();
      }

      document.getElementById("modal").addEventListener("click", function (e) {
        if (e.target === this) closeModal();
      });

      // Toggle start date field based on employee type
      document
        .getElementById("m-emp-type")
        .addEventListener("change", function () {
          const startDateField = document.getElementById("start-date-field");
          if (this.value === "Existing Employee") {
            startDateField.style.display = "none";
          } else {
            startDateField.style.display = "flex";
          }
        });

      document.addEventListener("keydown", function (e) {
        if (e.key === "Escape") closeModal();
        if (
          e.key === "Enter" &&
          document.getElementById("modal").classList.contains("open")
        ) {
          createHire();
        }
      });

      function esc(str) {
        return String(str || "")
          .replace(/&/g, "&amp;")
          .replace(/</g, "&lt;")
          .replace(/>/g, "&gt;")
          .replace(/"/g, "&quot;");
      }

      // Init
      load();
      initMsal();
      const firstId = Object.keys(db).sort(
        (a, b) => db[b].created - db[a].created,
      )[0];
      if (firstId) {
        activeId = firstId;
      }
      renderSidebar();
      renderMain();
    </script>
  </body>
</html>
