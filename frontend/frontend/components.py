from nicegui import ui


def navbar():
    left_drawer = ui.left_drawer(bordered=True, elevated=True).classes("w-full")

    with ui.header(elevated=True).classes("items-center justify-between"):
        with ui.row():
            ui.button(icon="menu", on_click=left_drawer.toggle).props(
                'flat round text-color="white"'
            )
            ui.label("🧬 DeepLEAP").classes("text-h5")

        with ui.row():
            dark_mode = ui.dark_mode()
            ui.button(icon="dark_mode", on_click=dark_mode.toggle).props(
                'flat round text-color="white"'
            )

    with left_drawer:
        with ui.list().classes("w-full"):
            drawer_element("home", "Home", "/")
            drawer_element("play_arrow", "Create Run", "/create")
            drawer_element("list", "View All Runs", "/runs")


def drawer_element(icon, text, link):
    with (
        ui.item(on_click=lambda: ui.navigate.to(link))
        .classes("w-full")
        .props("clickable")
    ):
        with ui.item_section().props("avatar"):
            ui.icon(icon)

        with ui.item_section():
            ui.label(text)
