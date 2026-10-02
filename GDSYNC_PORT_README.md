# BFDI GD-Sync port

This version removes the Talo networking/authentication layer and uses GD-Sync.

## Setup

1. Install the current GD-Sync plugin into `res://addons/GD-Sync/`.
2. Enable the GD-Sync plugin.
3. Configure your GD-Sync API keys under Project -> Tools -> GD-Sync.
4. Run the project.

The main menu now uses:
- Username: GD-Sync player username
- Lobby name: the GD-Sync lobby to create/join
- Create Lobby / Join Lobby

After joining a lobby, select a character and continue.

## Networking changes

- Talo Channels -> GD-Sync lobbies.
- Talo aliases -> GD-Sync client IDs and usernames.
- Talo player join/leave -> `GDSync.client_joined` / `GDSync.client_left`.
- Talo transform messages -> `PropertySynchronizer`.
- Talo ownership checks -> `GDSync.is_gdsync_owner`.
- Talo player member snapshots -> `GDSync.lobby_get_all_clients()`.
- Character choice is stored with `GDSync.player_set_data()`.
- Damage events are routed to the target's owning client with GD-Sync remote calls.

The uploaded `.godot` cache was not used as a dependency; the source project remains editable.
