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

    this.handleEvent("update_avatar", ({user_id, avatar_path}) => {
      const avatars = this.el.querySelectorAll(`img[data-user-avatar-id="${user_id}"]`);

      avatars.forEach(function(avatar) {
        avatar.src = `/uploads/${avatar_path}`;
      });
    });
  },

  
};

export default RoomMessages;
