function loadTopmenu() {
        var iframe = document.createElement("iframe");
        iframe.setAttribute("src", "/topmenu.html");
        iframe.setAttribute("width", "100%");
        iframe.setAttribute("height", "51px");
        iframe.frameBorder = 0;
        <% if @theme["favicon_data"] %>
            var favicon = document.createElement("link");
            favicon.setAttribute("type", "image/x-icon");
            favicon.setAttribute("href", "data:image/x-icon;base64,<%= @theme['favicon_data'] %>");
            favicon.setAttribute("rel", "icon");
            document.getElementsByTagName("head")[0].appendChild(favicon);
        <% end %>
        document.body.insertBefore(iframe, document.body.firstChild);
        document.title += ' [SF <%= @sf_version %>]';
};

if (document.addEventListener) {
    document.addEventListener("DOMContentLoaded", loadTopmenu, false);
} else {
    window.onload = loadTopmenu;
}