import os

base_dir = r"d:\PARTH\HackArena26\Campuscast"

structure = {
    "lib": {
        "main.dart": "",
        "app.dart": "",
        "core": {
            "constants": {
                "app_colors.dart": "",
                "app_strings.dart": "",
                "app_sizes.dart": ""
            },
            "theme": {
                "app_theme.dart": ""
            },
            "routes": {
                "app_router.dart": ""
            },
            "utils": {
                "validators.dart": "",
                "formatters.dart": "",
                "extensions.dart": ""
            },
            "enums": {
                "user_role.dart": ""
            }
        },
        "data": {
            "firebase": {
                "auth": {
                    "firebase_auth_service.dart": ""
                },
                "firestore": {
                    "admin_firestore.dart": "",
                    "section_firestore.dart": "",
                    "channel_firestore.dart": "",
                    "student_firestore.dart": ""
                },
                "storage": {
                    "firebase_storage_service.dart": ""
                },
                "fcm": {
                    "fcm_service.dart": ""
                }
            },
            "api": {
                "api_client.dart": "",
                "broadcast_api.dart": "",
                "ai_api.dart": ""
            },
            "models": {
                "user_model.dart": "",
                "section_model.dart": "",
                "channel_model.dart": "",
                "broadcast_model.dart": "",
                "event_model.dart": "",
                "poll_model.dart": "",
                "announcement_model.dart": ""
            }
        },
        "domain": {
            "repositories": {
                "auth_repository.dart": "",
                "section_repository.dart": "",
                "channel_repository.dart": "",
                "broadcast_repository.dart": "",
                "event_repository.dart": "",
                "poll_repository.dart": ""
            },
            "providers": {
                "auth_provider.dart": "",
                "section_provider.dart": "",
                "channel_provider.dart": "",
                "broadcast_provider.dart": "",
                "event_provider.dart": "",
                "poll_provider.dart": ""
            }
        },
        "presentation": {
            "common": {
                "widgets": {
                    "app_button.dart": "",
                    "app_input_field.dart": "",
                    "app_card.dart": "",
                    "live_badge.dart": "",
                    "audio_waveform.dart": "",
                    "event_banner_card.dart": "",
                    "bottom_nav_bar.dart": ""
                },
                "screens": {
                    "splash_screen.dart": ""
                }
            },
            "auth": {
                "screens": {
                    "login_screen.dart": ""
                }
            },
            "student": {
                "screens": {
                    "home_screen.dart": "",
                    "section_detail_screen.dart": "",
                    "channels_screen.dart": "",
                    "channel_detail_screen.dart": "",
                    "live_player_screen.dart": "",
                    "replay_screen.dart": "",
                    "profile_screen.dart": ""
                },
                "widgets": {
                    "section_chip.dart": "",
                    "live_now_card.dart": "",
                    "event_card.dart": "",
                    "channel_list_tile.dart": "",
                    "wifi_geo_tile.dart": ""
                }
            },
            "admin": {
                "screens": {
                    "dashboard_screen.dart": "",
                    "sections_screen.dart": "",
                    "section_detail_screen.dart": "",
                    "channels_screen.dart": "",
                    "channel_detail_screen.dart": "",
                    "profile_screen.dart": ""
                },
                "widgets": {
                    "stat_card.dart": "",
                    "section_list_tile.dart": "",
                    "channel_list_tile.dart": "",
                    "credentials_card.dart": ""
                }
            },
            "section_owner": {
                "screens": {
                    "dashboard_screen.dart": "",
                    "announce_screen.dart": "",
                    "go_live_screen.dart": "",
                    "schedule_screen.dart": "",
                    "events_screen.dart": "",
                    "post_event_screen.dart": "",
                    "profile_screen.dart": ""
                },
                "widgets": {
                    "live_control_bar.dart": "",
                    "announcement_card.dart": "",
                    "event_template_preview.dart": ""
                }
            },
            "channel_owner": {
                "screens": {
                    "dashboard_screen.dart": "",
                    "broadcast_screen.dart": "",
                    "go_live_screen.dart": "",
                    "schedule_screen.dart": "",
                    "engage_screen.dart": "",
                    "create_poll_screen.dart": "",
                    "post_event_screen.dart": "",
                    "profile_screen.dart": ""
                },
                "widgets": {
                    "poll_card.dart": "",
                    "broadcast_card.dart": "",
                    "member_list_tile.dart": ""
                }
            }
        }
    },
    "assets": {
        "images": {},
        "icons": {},
        "fonts": {}
    },
    "test": {
        "data": {},
        "domain": {},
        "presentation": {}
    },
    ".env": ""
}

def create_structure(current_path, current_struct):
    for key, value in current_struct.items():
        path = os.path.join(current_path, key)
        if isinstance(value, dict):
            os.makedirs(path, exist_ok=True)
            create_structure(path, value)
        else:
            if not os.path.exists(path):
                # Ensure parent dir exists
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, "w", encoding="utf-8") as f:
                    pass

create_structure(base_dir, structure)
print("Directory structure created successfully.")
