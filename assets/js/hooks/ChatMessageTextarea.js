const ChatMessageTextarea = {
  mounted() {
    this.el.focus();
    this.el.addEventListener('keydown', e => {
      console.log("keydown", e);
      if (e.key === 'Enter' && !e.shiftKey) {
        const form = document.getElementById("new-message-form");
        // Due to phx-debounce, we need to dispatch a change event to trigger the validation
        this.el.dispatchEvent(new Event("change", {bubbles: true, cancelable: true}));
        form.dispatchEvent(new Event("submit", {bubbles: true, cancelable: true}));
      }
    });
  },
};

export default ChatMessageTextarea;
