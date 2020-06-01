const map = {
    root: {
        user: "root",
        pwd: "{{ params.root_password }}",
        roles: [{role: "root", db: "admin"}]
    },
    viewer: {
        user: "viewer",
        pwd: "{{ params.viewer_password }}",
        roles: [{role: "readAnyDatabase", db: "admin"}]
    },
    oploguser: {
        user: "oploguser",
        pwd: "{{ params.oploguser_password }}",
        roles: [{role: "read", db: "local"}]
    },
    '{{ params.db_user }}': {
        user: "{{ params.db_user }}",
        pwd: "{{ params.db_password }}",
        roles: [{role: "readWrite", db: "{{ params.db_name }}"}]
    }
}

for (let user in Object.keys(map)) {
    const count = db.system.users.find({ user: user }).count();

    if (count === 0) {
        if (user !== map[user].user) {
            throw new Error('username should be ' + user + ', found: ' + map[user].user);
        }

        db.createUser(map[user]);
    }
}