// Replace with API Gateway invoke URL output
const API_ENDPOINT = "https://tbidg4h3f3.execute-api.us-east-1.amazonaws.com/status";

async function loadStatus() {
  const badge = document.getElementById("overall-badge");
  const tbody = document.getElementById("alarm-body");

  try {
    const res = await fetch(API_ENDPOINT);
    const data = await res.json();

    badge.textContent = data.overall_status;
    badge.className = "badge " + (data.overall_status === "OK" ? "ok" : "alarm");

    if (data.alarms.length === 0) {
      tbody.innerHTML = `<tr><td colspan="4">No alarms configured yet.</td></tr>`;
      return;
    }

    tbody.innerHTML = data.alarms.map(alarm => `
      <tr>
        <td>${alarm.name}</td>
        <td class="state-${alarm.state}">${alarm.state}</td>
        <td>${alarm.reason || "—"}</td>
        <td>${new Date(alarm.updated).toLocaleString()}</td>
      </tr>
    `).join("");
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="4">Failed to load status: ${err.message}</td></tr>`;
  }
}

loadStatus();
setInterval(loadStatus, 30000); // refresh every 30s