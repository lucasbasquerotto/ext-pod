db.createUser( {
    user: "root",
    pwd: "{{ root_password }}",
    roles: [ { role: "root", db: "admin" } ]
});

// db.createUser({
//     user:"root",
//     pwd: "{{ root_password }}",
//     roles:[
//         {role:"dbAdmin", db:"admin"},
//         {role:"readWriteAnyDatabase", db:"admin"},
//         {role:"backup", db:"admin"},
//         {role:"restore", db:"admin"}]
// });

db.createUser( {
    user: "viewer",
    pwd: "{{ viewer_password }}",
    roles: [ { role: "read", db: "rocketchat" } ]
});

db.createUser({
    user: "oploguser",
    pwd: "{{ oploguser_password }}",
    roles: [{role: "read", db: "local"}]
});

db.createUser({
    user: "rocket",
    pwd: "{{ rocket_password }}",
    roles: [{role: "readWrite", db: "rocketchat"}]
});