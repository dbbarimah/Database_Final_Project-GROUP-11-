// Attach the CSRF token to every htmx request. Flask-WTF's CSRFProtect
// reads it from the X-CSRFToken header when it's not in form data (which
// it isn't for htmx's inline-save/delete requests).
document.body.addEventListener("htmx:configRequest", (event) => {
  const token = document.querySelector('meta[name="csrf-token"]').content;
  event.detail.headers["X-CSRFToken"] = token;
});

// htmx doesn't swap 4xx/5xx responses into the page by default, so an
// action like "delete" that the database refuses (e.g. a foreign-key
// constraint) would otherwise fail silently. Surface it as an alert,
// using the database's own message when the server sent plain text.
document.body.addEventListener("htmx:responseError", (event) => {
  const text = event.detail.xhr.responseText;
  const message = text && text.length < 300
    ? text
    : "Something went wrong completing that action. Please try again.";
  alert(message);
});
