#include <iostream>
#include <vector>
#include <string>
#include <unordered_set>
#include <unordered_map>
#include <thread>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <unistd.h>
#include <signal.h>
#include <libproc.h>

// 1. 整包放行列表（包含主程序及其所有 Helper/插件/子进程）
const std::vector<std::string> ALLOWED_APPS = {
    "/Safari.app/",
    "/Visual Studio Code.app/",
    "/CLion.app/",
    "/Terminal.app/",
    "/iTerm.app/",
    "/Finder.app/"
};

// 2. 动态白名单（包含必须保护的系统组件、你点过“放行并记住”的软件、以及程序自身）
std::unordered_set<std::string> WHITELIST = {
    "Safari",
    "Finder",
    "System Preferences",
    "com.apple.WebKit.WebContent",
    "com.apple.WebKit.Networking",
    "com.apple.WebKit.GPU",
    "com.apple.Safari.SandboxBroker",
    "Terminal",
    "iTerm2",
    "osascript",
    "清风系统1"
};

std::string getProcessName(const std::string& path) {
    size_t pos = path.find_last_of('/');
    if (pos != std::string::npos) {
        return path.substr(pos + 1);
    }
    return path;
}

int askUserToKill(const std::vector<std::string>& app_names) {
    std::string list_str;
    size_t show_count = std::min(app_names.size(), (size_t)10);
    for (size_t i = 0; i < show_count; ++i) {
        list_str += "• " + app_names[i];
        if (i + 1 < show_count) list_str += "\\n";
    }
    if (app_names.size() > 10) {
        list_str += "\\n...等共 " + std::to_string(app_names.size()) + " 个进程";
    }

    std::string cmd = "osascript -e 'activate' "
                      "-e 'display dialog \"【清风系统1】检测到以下多余软件：\\n\\n" 
                      + list_str + 
                      "\\n\\n是否彻底强制结束？\" "
                      "with title \"清风系统 - 安全确认\" "
                      "buttons {\"放行并记住\", \"彻底清理\"} "
                      "default button \"彻底清理\" "
                      "with icon caution "
                      "giving up after 15' 2>/dev/null";

    FILE* pipe = popen(cmd.c_str(), "r");
    if (!pipe) return -1;

    char buffer[256];
    std::string result = "";
    while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
        result += buffer;
    }
    pclose(pipe);

    if (result.find("gave up:true") != std::string::npos) return -1;
    if (result.find("彻底清理") != std::string::npos) return 1;
    if (result.find("放行并记住") != std::string::npos) return 0;
    return -1;
}

int main() {
    pid_t my_pid = getpid();
    std::cout << "【清风系统1】已启动，全雷达巡检中..." << std::endl;

    while (true) {
        int num_pids = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
        if (num_pids <= 0) continue;

        std::vector<pid_t> pids(num_pids);
        num_pids = proc_listpids(PROC_ALL_PIDS, 0, pids.data(), pids.size() * sizeof(pid_t));
        int count = num_pids / sizeof(pid_t);

        std::unordered_map<std::string, std::vector<pid_t>> targets;

        for (int i = 0; i < count; ++i) {
            pid_t pid = pids[i];
            if (pid <= 0 || pid == my_pid) continue;

            char path_buf[PROC_PIDPATHINFO_MAXSIZE];
            if (proc_pidpath(pid, path_buf, sizeof(path_buf)) > 0) {
                std::string full_path(path_buf);
                std::string proc_name = getProcessName(full_path);

                // 1. 彻底跳过所有 /System/ 和 /usr/ 下的苹果原装系统软件与服务
                if (full_path.rfind("/System/", 0) == 0 || full_path.rfind("/usr/", 0) == 0) {
                    continue;
                }

                // 2. 排除所有系统扩展 (.appex)
                if (full_path.find(".appex/") != std::string::npos) {
                    continue;
                }

                // 3. 检查整包放行列表（Safari、VS Code、CLion 等）
                bool is_allowed_app = false;
                for (const auto& app_path : ALLOWED_APPS) {
                    if (full_path.find(app_path) != std::string::npos) {
                        is_allowed_app = true;
                        break;
                    }
                }
                if (is_allowed_app) continue;

                // 4. 扩大扫描雷达：覆盖 /Applications/、/Library/Frameworks/（如 IDLE/Python）及用户目录软件
                bool is_third_party = (full_path.rfind("/Applications/", 0) == 0) ||
                                      (full_path.rfind("/Library/Frameworks/", 0) == 0) ||
                                      (full_path.find("/Users/") != std::string::npos && full_path.find(".app/") != std::string::npos);

                if (is_third_party) {
                    if (WHITELIST.find(proc_name) == WHITELIST.end()) {
                        targets[proc_name].push_back(pid);
                    }
                }
            }
        }

        if (!targets.empty()) {
            std::vector<std::string> names;
            for (const auto& pair : targets) {
                names.push_back(pair.first);
            }

            std::cout << "[巡检] 发现 " << names.size() << " 个多余软件，弹出确认框..." << std::endl;
            int choice = askUserToKill(names);

            if (choice == 1) {
                for (const auto& pair : targets) {
                    for (pid_t target_pid : pair.second) {
                        kill(target_pid, SIGKILL); 
                    }
                    std::cout << "[已彻底抹除] " << pair.first << std::endl;
                }
            } else if (choice == 0) {
                for (const auto& name : names) {
                    WHITELIST.insert(name);
                    std::cout << "[已放行并记住] " << name << std::endl;
                }
            } else {
                std::cout << "[跳过] 未选择或超时，5秒后继续..." << std::endl;
            }
        }

        std::this_thread::sleep_for(std::chrono::seconds(5));
    }

    return 0;
}
