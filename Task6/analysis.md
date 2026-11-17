# Отчёт по результатам анализа Kubernetes Audit Log

## Подозрительные события

1. Доступ к секретам:
   - Кто: `kubernetes-admin` из группы `kubeadm:cluster-admins`, клиент `kubectl/v1.36.1`, адрес `172.19.0.1`. Повторный запрос шел от того же пользователя с impersonation `system:serviceaccount:secure-ops:monitoring`.
   - Где: `list` секретов в namespace `kube-system`. Свой запрос администратора завершился кодом 200. Запрос от имени monitoring завершился кодом 403.
   - Почему подозрительно: учетная запись мониторинга запрашивает секреты системного namespace. Отдельного секрета `default-token` в кластере нет, поэтому вызов превратился в список всех секретов. RBAC этот список запретил.

2. Привилегированные поды:
   - Кто: `kubernetes-admin`, `kubectl/v1.36.1`, адрес `172.19.0.1`.
   - Комментарий: в namespace `secure-ops` создан pod `privileged-pod`, код 201. У контейнера `pwn` образ `alpine` и `securityContext.privileged: true`. Такой под работает с правами узла.

3. Использование kubectl exec в чужом поде:
   - Кто: `kubernetes-admin`, `kubectl/v1.36.1`, адрес `172.19.0.1`.
   - Что делал: открыл `pods/exec` в namespace `kube-system` на pod `coredns-589f44dc88-n88fs`, команда `cat /etc/resolv.conf`. В аудите это `verb: get` и код 101, а не `create`. Сеанс API открыл, процесс в контейнере CoreDNS не стартовал: в образе нет `cat`.

4. Создание RoleBinding с правами cluster-admin:
   - Кто: `kubernetes-admin`, `kubectl/v1.36.1`, адрес `172.19.0.1`.
   - К чему привело: в namespace `secure-ops` создан RoleBinding `escalate-binding`, код 201. Субъект `ServiceAccount/secure-ops/monitoring`, roleRef `ClusterRole/cluster-admin`. В теле аудита roleRef нет: событие записано с уровнем Metadata, потому что первое правило политики ищет `roles` и `rolebindings` в core-группе, а RoleBinding относится к `rbac.authorization.k8s.io`. После создания monitoring может читать секреты и создавать поды в `secure-ops`. В `kube-system` те же действия по-прежнему запрещены: RoleBinding не раздает ClusterRole за пределы своего namespace.

5. Удаление audit-policy.yaml:
   - Кто: до API запрос не дошел. `kubectl delete -f /etc/kubernetes/audit-policy.yaml --as=admin` остановился на клиенте: файла по этому пути нет.
   - Возможные последствия: в `audit.log` нет события удаления политики. Строки с текстом `audit-policy` относятся к spec пода `kube-apiserver`, где указан путь к файлу политики. Если файл политики удалить на узле control plane, API-сервер перестанет записывать следующие действия.

## Вывод

Кластер целиком не захвачен: чтение секретов `kube-system` от имени monitoring отклонено. Компрометацией являются привилегированный под на узле и выдача `cluster-admin` учетной записи мониторинга внутри `secure-ops`. Exec в CoreDNS показывает доступ администратора к чужому системному поду. Ошибка RBAC в том, что сервисному аккаунту мониторинга выдали роль `cluster-admin` без отдельного согласования. Ограничение только namespace `secure-ops` не отменяет эту выдачу.
