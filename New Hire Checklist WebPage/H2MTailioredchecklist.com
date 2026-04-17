<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Laptop Deployment Checklist</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/docx@8.5.0/build/index.js"></script>
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
        margin-top: 2px;
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
            onclick="openNewHireModal()"
          >
            <span>+</span> New Deployment
          </button>
        </div>
        <div class="hire-list" id="hire-list"></div>
        <div class="sidebar-footer"></div>
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

        <div class="field">
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

    <script>
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
        return Object.values(h.checks || {}).filter(Boolean).length;
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
              const pct = Math.round((done / TOTAL_ITEMS) * 100);
              const active = id === activeId ? " active" : "";
              return `<div class="hire-item${active}" onclick="selectHire('${id}')">
        <div class="hire-item-inner">
          <div class="hire-name">${esc(h.name)}</div>
          <div class="hire-meta">${esc(h.dept || "")}${h.office ? " • " + esc(h.office) : ""}</div>
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
        const pct = Math.round((done / TOTAL_ITEMS) * 100);

        const sectionPills = SECTIONS.map((s, si) => {
          const secDone = s.items.filter(
            (_, ii) => h.checks?.[`${si}_${ii}`],
          ).length;
          return `<span class="phase-pill${secDone === s.items.length ? " done" : ""}">${esc(s.title)}</span>`;
        }).join("");

        const completeBanner =
          done === TOTAL_ITEMS
            ? `<div class="complete-banner">✓ Deployment complete -- laptop ready for ${esc(h.name)}</div>`
            : "";

        const sectionsHtml = SECTIONS.map((sec, si) => {
          const secDone = sec.items.filter(
            (_, ii) => h.checks?.[`${si}_${ii}`],
          ).length;
          const allDone = secDone === sec.items.length;
          const isOpen = h.open?.[si] !== false;
          const itemsHtml = sec.items
            .map((item, ii) => {
              const key = `${si}_${ii}`;
              const checked = !!h.checks?.[key];
              return `<div class="check-item" onclick="toggleItem('${si}','${ii}')">
        <input type="checkbox" ${checked ? "checked" : ""} onclick="event.stopPropagation();toggleItem('${si}','${ii}')">
        <div class="check-text">
          <div class="check-label${checked ? " done" : ""}">${esc(item.text)}</div>
          ${item.note ? `<div class="check-note">${esc(item.note)}</div>` : ""}
        </div>
      </div>`;
            })
            .join("");
          return `<div class="section${isOpen ? " open" : ""}" id="sec-${si}">
      <div class="section-header" onclick="toggleSection(${si})">
        <span class="section-num">0${si + 1}</span>
        <span class="section-title">${esc(sec.title)}</span>
        <span class="section-badge${allDone ? " done" : ""}">${secDone}/${sec.items.length}</span>
        <span class="chevron">►</span>
      </div>
      <div class="section-body">${itemsHtml}</div>
    </div>`;
        }).join("");

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
        ${subLine ? `<div class="hire-subtitle">${esc(subLine)}</div>` : ""}
        ${metaLine ? `<div class="hire-subtitle" style="margin-top:3px;font-size:11px;font-weight:500">${metaLine}</div>` : ""}
      </div>
      <div class="header-actions">
        <button class="btn export" onclick="exportPDF()">📄 Export PDF</button>
        <!-- <button class="btn export" onclick="exportWord()">📑 Export Word</button> -->
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
        <div class="progress-fraction">${done}<span style="font-size:16px;color:var(--text-faint)"> / ${TOTAL_ITEMS}</span></div>
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
        if (!activeId || !confirm("Reset all checkboxes for this deployment?"))
          return;
        db[activeId].checks = {};
        save();
        renderSidebar();
        renderMain();
      }

      function deleteHire(id) {
        if (
          !confirm(
            `Delete checklist for ${db[id].name}? This cannot be undone.`,
          )
        )
          return;
        delete db[id];
        if (activeId === id) activeId = null;
        save();
        renderSidebar();
        renderMain();
      }

      // ============================================================
      // Export Functions
      // ============================================================
      function exportPDF() {
        if (!activeId) return;
        const h = db[activeId];
        const element = document.getElementById("main").cloneNode(true);

        // Remove export buttons before PDF
        const btns = element.querySelectorAll(".header-actions");
        btns.forEach((b) => b.remove());

        const opt = {
          margin: [20, 20, 20, 20],
          filename: `Setup & Install Checklist - ${h.name.replace(/\s+/g, "-")}_${new Date().toISOString().split("T")[0]}.pdf`,
          image: { type: "jpeg", quality: 0.98 },
          html2canvas: { scale: 2 },
          jsPDF: { orientation: "portrait", unit: "mm", format: "a4" },

          pagebreak: {
            mode: ["avoid-all", "css", "legacy"],
          },
        };

        html2pdf().set(opt).from(element).save();
      }

      function exportWord() {
        if (!activeId) return;
        const h = db[activeId];
        const done = getChecked(h);
        const pct = Math.round((done / TOTAL_ITEMS) * 100);

        const sections = [];

        // Title and header
        sections.push(
          new docx.Paragraph({
            text: `${h.name}`,
            heading: docx.HeadingLevel.HEADING_1,
            bold: true,
            spacing: { after: 100 },
          }),
        );

        // Employee info
        const infoText = [h.empType, h.department, h.office, h.pcName, h.start]
          .filter(Boolean)
          .join(" • ");
        sections.push(
          new docx.Paragraph({
            text: infoText,
            spacing: { after: 200 },
          }),
        );

        // Progress
        sections.push(
          new docx.Paragraph({
            text: `Progress: ${done} / ${TOTAL_ITEMS} items (${pct}%)`,
            bold: true,
            spacing: { after: 200 },
          }),
        );

        // Sections with checklist items
        SECTIONS.forEach((sec, si) => {
          sections.push(
            new docx.Paragraph({
              text: sec.title,
              heading: docx.HeadingLevel.HEADING_2,
              bold: true,
              spacing: { after: 100 },
            }),
          );

          sec.items.forEach((item, ii) => {
            const key = `${si}_${ii}`;
            const checked = !!h.checks?.[key];
            sections.push(
              new docx.Paragraph({
                text: `${checked ? "☑" : "☐"} ${item.text}${item.note ? " (" + item.note + ")" : ""}`,
                spacing: { after: 50 },
              }),
            );
          });

          sections.push(
            new docx.Paragraph({ text: "", spacing: { after: 100 } }),
          );
        });

        // Notes
        sections.push(
          new docx.Paragraph({
            text: "Deployment Notes",
            heading: docx.HeadingLevel.HEADING_2,
            bold: true,
            spacing: { after: 100 },
          }),
        );

        sections.push(
          new docx.Paragraph({
            text: h.notes || "(No notes)",
            spacing: { after: 200 },
          }),
        );

        // Generated info
        sections.push(
          new docx.Paragraph({
            text: `Generated: ${new Date().toLocaleString()}`,
            italics: true,
            color: "999999",
            spacing: { after: 0 },
          }),
        );

        const doc = new docx.Document({
          sections: [
            {
              properties: {},
              children: sections,
            },
          ],
        });

        docx.Packer.toBlob(doc).then((blob) => {
          const url = URL.createObjectURL(blob);
          const a = document.createElement("a");
          a.href = url;
          a.download = `Deployment_${h.name.replace(/\s+/g, "_")}_${new Date().toISOString().split("T")[0]}.docx`;
          a.click();
          URL.revokeObjectURL(url);
        });
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
        document.getElementById("modal").classList.add("open");
        setTimeout(() => document.getElementById("m-name").focus(), 80);
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
          dept: document.getElementById("m-dept").value.trim(),
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
