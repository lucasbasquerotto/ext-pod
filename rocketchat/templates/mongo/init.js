db.createUser( {
    user: "root",
    pwd: "{{ params.root_password }}",
    roles: [ "root" ]
});

db.createUser( {
    user: "viewer",
    pwd: "{{ params.viewer_password }}",
    roles: [ "readAnyDatabase" ]
});

db.createUser({
    user: "oploguser",
    pwd: "{{ params.oploguser_password }}",
    roles: [{role: "read", db: "local"}]
});

db.createUser({
    user: "{{ params.db_user }}",
    pwd: "{{ params.db_password }}",
    roles: [{role: "readWrite", db: "{{ params.db_name }}"}]
});