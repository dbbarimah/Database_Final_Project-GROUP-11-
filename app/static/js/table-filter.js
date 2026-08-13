// Live filter-as-you-type for any table. Add data-filter-target="#id" to
// a search input pointing at the table's id; rows are shown/hidden by
// plain substring match against the row's own text, entirely client-side.
document.addEventListener("input", (event) => {
  const input = event.target.closest("[data-filter-target]");
  if (!input) return;

  const table = document.querySelector(input.dataset.filterTarget);
  if (!table) return;

  const query = input.value.trim().toLowerCase();
  let visible = 0;

  table.querySelectorAll("tbody tr").forEach((row) => {
    const match = !query || row.textContent.toLowerCase().includes(query);
    row.classList.toggle("d-none", !match);
    if (match) visible += 1;
  });

  const empty = table.parentElement.querySelector("[data-filter-empty]");
  if (empty) empty.classList.toggle("d-none", visible > 0);
});
