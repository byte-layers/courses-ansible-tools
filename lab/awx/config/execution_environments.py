# L'execution environment des jobs et du plan de contrôle.
GLOBAL_JOB_EXECUTION_ENVIRONMENTS = [
    {'name': 'AWX EE (24.6.1)', 'image': 'quay.io/ansible/awx-ee:24.6.1'},
]
CONTROL_PLANE_EXECUTION_ENVIRONMENT = 'quay.io/ansible/awx-ee:24.6.1'
