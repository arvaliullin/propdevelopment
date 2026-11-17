# Проверка Task7

Кластер kind в Docker Desktop, узел desktop-control-plane.

Порядок: `make task7-all`.

Отдельные цели: `task7-gatekeeper`, `task7-audit`, `task7-namespace`, `task7-policies`, `task7-secure`, `task7-verify`, `task7-denied`.

В `audit-zone` включен PodSecurity `restricted`. Он отклоняет небезопасные поды раньше вебхука Gatekeeper. `validate-security.sh` подставляет namespace `gatekeeper-check`, где меток PodSecurity нет, и отказ приходит от `validation.gatekeeper.sh`.

Правило `readOnlyRootFilesystem: true` находится в шаблоне `K8sRequireNonRoot`, файл `gatekeeper/constraint-templates/runasnonroot.yaml`. Отдельного файла для него в структуре задания нет.

Ограничения Gatekeeper действуют в `audit-zone` и `gatekeeper-check`.
