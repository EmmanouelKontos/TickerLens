// Windows GUI entry. Qt on MinGW defines QT_NEEDS_QMAIN so the app entry is
// named qMain, not main. Call the correct symbol.
#ifdef _WIN32
#  include <windows.h>
#  include <shellapi.h>
#  include <string>
#  include <vector>

#  ifdef QT_NEEDS_QMAIN
extern int qMain(int argc, char *argv[]);
static int callAppMain(int argc, char **argv) { return qMain(argc, argv); }
#  else
extern int main(int argc, char *argv[]);
static int callAppMain(int argc, char **argv) { return main(argc, argv); }
#  endif

int WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
    int argc = 0;
    LPWSTR *argvw = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (!argvw)
        return callAppMain(0, nullptr);

    std::vector<std::string> storage;
    std::vector<char *> argv;
    storage.reserve(static_cast<size_t>(argc));
    argv.reserve(static_cast<size_t>(argc));

    for (int i = 0; i < argc; ++i) {
        const int n = WideCharToMultiByte(CP_UTF8, 0, argvw[i], -1, nullptr, 0, nullptr, nullptr);
        std::string s(static_cast<size_t>(n > 0 ? n : 1), '\0');
        if (n > 0)
            WideCharToMultiByte(CP_UTF8, 0, argvw[i], -1, s.data(), n, nullptr, nullptr);
        while (!s.empty() && s.back() == '\0')
            s.pop_back();
        storage.push_back(std::move(s));
    }
    for (auto &s : storage)
        argv.push_back(s.data());

    LocalFree(argvw);
    return callAppMain(argc, argv.data());
}
#endif
