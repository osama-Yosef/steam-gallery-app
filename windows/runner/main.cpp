#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>
#include <string>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // Safe graphics, for old graphics cards that drew the app's colours as
  // nothing (see lib/core/theme/safe_graphics.dart): on when a file named
  // "safe_graphics" sits next to the .exe or --safe-graphics is passed.
  // Impeller is turned off — the older Skia renderer copes with those
  // drivers — and the flag is passed on so the app draws flat.
  bool safe_graphics =
      std::find(command_line_arguments.begin(), command_line_arguments.end(),
                "--safe-graphics") != command_line_arguments.end();
  if (!safe_graphics) {
    wchar_t exe_path[MAX_PATH];
    DWORD length = ::GetModuleFileNameW(nullptr, exe_path, MAX_PATH);
    if (length > 0 && length < MAX_PATH) {
      std::wstring marker(exe_path, length);
      marker = marker.substr(0, marker.find_last_of(L"\\/") + 1) +
               L"safe_graphics";
      safe_graphics =
          ::GetFileAttributesW(marker.c_str()) != INVALID_FILE_ATTRIBUTES;
    }
    if (safe_graphics) command_line_arguments.push_back("--safe-graphics");
  }
  if (safe_graphics) {
    project.set_impeller_switch(flutter::ImpellerSwitch::Disabled);
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  // Shown in the title bar, the taskbar and Alt-Tab, so it carries the
  // product's name (Brand.name) rather than the Flutter project id.
  if (!window.Create(L"مكوجي", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
