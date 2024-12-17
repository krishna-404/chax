const RoomMessages = {
  mounted() {
    this.el.scrollTo({
      top: this.el.scrollHeight,
      behavior: "smooth",
    });
    this.handleEvent("scroll_messages_to_bottom", () => {
      this.el.scrollTo({
        top: this.el.scrollHeight,
        behavior: "smooth",
      });
    });
  },
};

export default RoomMessages;
