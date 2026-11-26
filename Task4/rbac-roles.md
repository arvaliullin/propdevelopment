| Роль | Права роли | Группы пользователей |
| --- | --- | --- |
| cluster-operator | Создание и изменение namespace, узлов, RBAC и сетевых политик. Чтение секретов не входит в роль. | devops: DevOps и инженеры по эксплуатации |
| secret-auditor | get, list, watch для secrets во всех namespace. | infosec: специалист по ИБ |
| cluster-viewer | get, list, watch для pod, deployment, service, configmap и namespace. Секреты и изменение ресурсов недоступны. | viewers: менеджеры, бизнес-аналитики, аналитики BI |
| namespace-developer | В своем namespace: pod, deployment, service, configmap, secret, ingress. | sales-developers, housing-developers, finance-developers, data-developers: разработчики соответствующего домена |
