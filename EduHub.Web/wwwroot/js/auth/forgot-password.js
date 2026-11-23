
    'use strict';

    /* BACKEND INTEGRATION
     * Set RESET_REQUEST_ENDPOINT to your HTTPS server endpoint accepting POST JSON
     * {email}. Backend must generate single-use, expiring reset tokens and deliver
     * email securely. Rate-limit requests, and return the same generic success
     * response for existing and non-existing accounts to prevent enumeration.
     * Without an endpoint, this page never claims to send an email.
     */
    const RESET_REQUEST_ENDPOINT = '';
    const form = document.getElementById('recoveryForm');
    const emailInput = document.getElementById('email');
    const emailError = document.getElementById('emailError');
    const feedback = document.getElementById('formFeedback');
    const submitButton = document.getElementById('sendResetButton');
    const requestState = document.getElementById('requestState');
    const successState = document.getElementById('successState');
    const confirmationEmail = document.getElementById('confirmationEmail');

    function validateEmail(showError = false) {
      const valid = emailInput.value.trim() !== '' && emailInput.validity.valid;
      const invalid = showError && !valid;
      emailInput.classList.toggle('is-invalid', invalid);
      emailInput.setAttribute('aria-invalid', String(invalid));
      emailError.textContent = invalid ? 'Please enter a valid email address.' : '';
      emailError.classList.toggle('is-visible', invalid);
      return valid;
    }
    function showFeedback(message, type = 'info') {
      feedback.textContent = message;
      feedback.className = 'form-feedback is-visible' + (type === 'error' ? ' is-error' : '');
    }
    function clearFeedback() { feedback.textContent = ''; feedback.className = 'form-feedback'; }

    emailInput.addEventListener('blur', () => validateEmail(true));
    emailInput.addEventListener('input', () => {
      if (emailInput.classList.contains('is-invalid')) validateEmail(true);
      clearFeedback();
    });
    form.addEventListener('submit', async event => {
      event.preventDefault();
      if (!validateEmail(true)) {
        showFeedback('Please correct the highlighted email address.', 'error');
        emailInput.focus();
        return;
      }
      if (!RESET_REQUEST_ENDPOINT) {
        showFeedback('This is a static account-recovery demo. No reset link was sent.');
        return;
      }
      const endpoint = new URL(RESET_REQUEST_ENDPOINT, window.location.href);
      if (endpoint.protocol !== 'https:' && endpoint.hostname !== 'localhost') {
        showFeedback('Please configure a secure HTTPS account-recovery endpoint.', 'error');
        return;
      }
      const previousText = submitButton.textContent;
      submitButton.disabled = true;
      submitButton.setAttribute('aria-busy', 'true');
      submitButton.innerHTML = '<i class="fa-solid fa-spinner fa-spin me-2" aria-hidden="true"></i> Sending...';
      clearFeedback();
      try {
        const response = await fetch(endpoint.href, {
          method: 'POST', credentials: 'same-origin',
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
          body: JSON.stringify({ email: emailInput.value.trim() })
        });
        if (!response.ok) {
          showFeedback(response.status === 429 ? 'Too many requests. Please try again later.' : 'We could not process your request. Please try again.', 'error');
          return;
        }
        confirmationEmail.textContent = emailInput.value.trim();
        requestState.hidden = true;
        successState.hidden = false;
        document.getElementById('tryAnotherEmail').focus({ preventScroll: true });
      } catch (_) {
        showFeedback('Unable to reach the recovery service. Please try again.', 'error');
      } finally {
        submitButton.disabled = false;
        submitButton.removeAttribute('aria-busy');
        submitButton.textContent = previousText;
      }
    });
    document.getElementById('tryAnotherEmail').addEventListener('click', () => {
      successState.hidden = true;
      requestState.hidden = false;
      emailInput.value = '';
      confirmationEmail.textContent = '';
      validateEmail(false);
      clearFeedback();
      emailInput.focus({ preventScroll: true });
    });
  