const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp({
    credential: admin.credential.applicationDefault()
});

var db = admin.firestore();
var FieldValue = admin.firestore.FieldValue;

exports.onPostCreate = functions.firestore
.document('post/{postID}')
.onCreate((snap, context) => {
    let postID = context.params.postID;
    let post = snap.data();
    let userDB = db.collection('users').doc(post.uid)
    return userDB.get().then((userDoc) => {
        if(userDoc.exists){
            let posts = userDoc.data().posts;
            posts.push(postID);
            userDB.update({
                posts:posts
            });
        }
    });
});

exports.onPostDelete = functions.firestore
.document('post/{postID}')
.onDelete((snap, context) => {
    let postID = context.params.postID
    let post = snap.data()
    let userDB = db.collection('users').doc(post.uid)
    let postDB = userDB.collection('posts').doc(postID)
    return postDB.delete()
})

exports.onUserPostDelete = functions.firestore
.document('users/{uid}/posts/{postID}')
.onDelete((snap, context) => {
    let postID = context.params.postID
    let postDB = db.collection('post').doc(postID)
    return postDB.delete()
})

exports.upvote = functions.https.onRequest((req, res) => {
    let uid = req.query.uid;
    let postID = req.query.post;
    let postRef = db.collection('post').doc(postID)
    let voteRef = postRef.collection('votes').doc(uid)
    voteRef.get().then((voteDoc) => {
        var deltaUp = 1
        var deltaDown = 0
        if(voteDoc.exists){
            console.log("exists");
            if(voteDoc.data().up){
                deltaUp--
            }
            else{
                deltaDown--
            }
        }
        postRef.update({
            upvotes: FieldValue.increment(deltaUp),
            downvotes: FieldValue.increment(deltaDown)
        }).then(() => {
            postRef.get().then((postDoc) => {
                let postData = postDoc.data();
                voteRef.set({ up: true });
                postRef.update({score: postData.upvotes - postData.downvotes});
                res.status(200).json({
                    upvotes: postData.upvotes,
                    downvotes: postData.downvotes
                });
            });
        }).catch((data) => {
            res.status(400).json(data);
        });
    });
});

exports.downvote = functions.https.onRequest((req, res) => {
    let uid = req.query.uid;
    let postID = req.query.post;
    let postRef = db.collection('post').doc(postID)
    let voteRef = postRef.collection('votes').doc(uid)
    voteRef.get().then((voteDoc) => {
        var deltaUp = 0
        var deltaDown = 1
        if(voteDoc.exists){
            console.log("exists");
            if(voteDoc.data().up){
                deltaUp--
            }
            else{
                deltaDown--
            }
        }
        postRef.update({
            upvotes: FieldValue.increment(deltaUp),
            downvotes: FieldValue.increment(deltaDown)
        }).then(() => {
            postRef.get().then((postDoc) => {
                let postData = postDoc.data();
                voteRef.set({ up: false });
                postRef.update({score: postData.upvotes - postData.downvotes});
                res.status(200).json({
                    upvotes: postData.upvotes,
                    downvotes: postData.downvotes
                });
            });
        }).catch((data) => {
            res.status(400).json(data);
        });
    });
});

/*exports.getUserFeed2 = functions.https.onRequest((req, res) => {
    let uid = req.query.uid;
    let page = parseInt(req.query.page);
    let itemsPerPage = 50;
    if (isNaN(page) || page <= 0){
        page = 1;
    }
    let userDB = db.collection('users').doc(uid)
    return userDB.get().then((userDoc) => {
        if(userDoc.exists){
            var followingDBs = []
            var following = userDoc.data().following;
            following.push(uid);
            following.forEach((user) => {
                followingDBs.push(db.collection('users').doc(user).get());
            });
            Promise.all(followingDBs).then((followingDocs) => {
                var postData = {}
                followingDocs.forEach((followingDoc) => {
                    if(followingDoc.exists){
                        let followingPosts = followingDoc.data().posts;
                        followingPosts.forEach((post) => {
                            postData[post] = {
                                username: followingDoc.data().username,
                                uid: followingDoc.id,
                                profilePicURL: followingDoc.data().profilePicURL,
                                post: post,
                                imageURL: '',
                                upvotes: 0,
                                downvotes: 0,
                                timestamp: null,
                                description: '',
                                upvoted: false,
                                downvoted: false
                            }
                        });
                    }
                });
                postDBs = []
                for(post in postData){
                    postDBs.push(db.collection('post').doc(post).get());
                }
                Promise.all(postDBs).then((posts) => {
                    posts.forEach((post) => {
                        if(post.exists){
                            postData[post.id]['imageURL'] = post.data().photoURL;
                            postData[post.id]['upvotes'] = post.data().upvotes;
                            postData[post.id]['downvotes'] = post.data().downvotes;
                            postData[post.id]['timestamp'] = post.data().timestamp;
                            postData[post.id]['description'] = post.data().description;
                        }
                    });
                    postArray = []
                    for(key in postData){
                        postArray.push(postData[key])
                    }
                    postArray.sort(function(a, b) {
                        return b['timestamp'].seconds - a['timestamp'].seconds;
                    });
                    postArray = postArray.slice(0, page*itemsPerPage);
                    var votePromises = []
                    postArray.forEach((p) => {
                        let voteRef = db.collection('post').doc(p['post']).collection('votes').doc(uid);
                        votePromises.push(voteRef.get())
                    });
                    Promise.all(votePromises).then((voteDocs) => {
                        for(i in voteDocs) {
                            if(voteDocs[i].exists){
                                postArray[i]['upvoted'] = voteDocs[i].data().up
                                postArray[i]['downvoted'] = !voteDocs[i].data().up
                            }
                        }
                        res.status(200).json({
                            posts: postArray
                        });
                    });
                });
            });
        }
    });
});

exports.getDiscoverFeed2 = functions.https.onRequest((req, res) => {
    let uid = req.query.uid;
    let page = parseInt(req.query.page);
    let itemsPerPage = 50;
    if (isNaN(page) || page <= 0){
        page = 1;
    }
    let usersDB = db.collection('users');
    return usersDB.get().then((users) => {
        var postData = {}
        users.docs.forEach((user) => {
            if(user.exists){
                let userPosts = user.data().posts;
                userPosts.forEach((post) => {
                    postData[post] = {
                        username: user.data().username,
                        uid: user.id,
                        profilePicURL: user.data().profilePicURL,
                        post: post,
                        imageURL: '',
                        upvotes: 0,
                        downvotes: 0,
                        timestamp: null,
                        description: '',
                        upvoted: false,
                        downvoted: false
                    }
                });
            }
        });
        postDBs = []
        for(post in postData){
            postDBs.push(db.collection('post').doc(post).get());
        }
        Promise.all(postDBs).then((posts) => {
            posts.forEach((post) => {
                if(post.exists){
                    postData[post.id]['imageURL'] = post.data().photoURL;
                    postData[post.id]['upvotes'] = post.data().upvotes;
                    postData[post.id]['downvotes'] = post.data().downvotes;
                    postData[post.id]['timestamp'] = post.data().timestamp;
                    postData[post.id]['description'] = post.data().description;
                }
            });
            postArray = []
            for(key in postData){
                postArray.push(postData[key])
            }
            postArray.sort(function(a, b) {
                return (b['upvotes'] - b['downvotes']) - (a['upvotes'] - a['downvotes']);
            });
            postArray = postArray.slice(0, page*itemsPerPage);
            var votePromises = []
            postArray.forEach((p) => {
                let voteRef = db.collection('post').doc(p['post']).collection('votes').doc(uid);
                votePromises.push(voteRef.get())
            });
            Promise.all(votePromises).then((voteDocs) => {
                for(i in voteDocs) {
                    if(voteDocs[i].exists){
                        postArray[i]['upvoted'] = voteDocs[i].data().up
                        postArray[i]['downvoted'] = !voteDocs[i].data().up
                    }
                }
                res.status(200).json({
                    posts: postArray
                });
            });
        });
    });
});*/

exports.getDiscoverFeed = functions.https.onRequest((req, res) => {
    let expireTime = (new Date().getTime() * 0.001) - 86400
    let expireSeconds = parseInt(expireTime)
    let expireNano = parseInt((expireTime - expireSeconds) * 1000000000)
    let expireTimestamp = new admin.firestore.Timestamp(expireSeconds, expireNano)
    let numPosts = 50
    let maxScore = parseInt(req.query.maxScore)
    let postIDs = []
    var postRef = db.collection('post')
    if(!isNaN(maxScore)){
        postRef = postRef.where('score', '<=', maxScore)
    }
    return postRef.get().then((posts) => {
        posts.docs.forEach((post) => {
            if(post.exists){
                let postData = post.data()
                let postTimestamp = postData.timestamp.toDate()
                if(postTimestamp <= expireTimestamp.toDate()){
                    post.ref.delete()
                }
                else{
                    postIDs.push({
                        id: post.id,
                        uid: postData.uid,
                        color: postData.color,
                        timestamp: postData.timestamp,
                        upvotes: postData.upvotes,
                        downvotes: postData.downvotes
                    })
                }
            }
        })
        postIDs.slice(0, numPosts)
        res.status(200).json({posts: postIDs})
    })
})

exports.getUserFeed = functions.https.onRequest((req, res) => {
    let uid = req.query.uid;
    let time = parseFloat(req.query.timestamp)
    let numPosts = 50;
    if (isNaN(time) || time < 0){
        time = new Date().getTime() * 0.001
    }
    var seconds = parseInt(time)
    var nano = parseInt((time - seconds) * 1000000000)
    let expireTime = (new Date().getTime() * 0.001) - 86400
    let expireSeconds = parseInt(expireTime)
    let expireNano = parseInt((expireTime - expireSeconds) * 1000000000)

    let timestamp = new admin.firestore.Timestamp(seconds, nano)
    let expireTimestamp = new admin.firestore.Timestamp(expireSeconds, expireNano)
    let followedUsers = [uid]
    let followingDB = db.collection('users').doc(uid).collection('following')
    followingDB.get().then((following) => {
        let followedPostsDBs = []
        let postIDs = []
        following.docs.forEach((followedUser) => {
            if(followedUser.exists){
                if(followedUser.data().following){
                    followedUsers.push(followedUser.id)
                }
            }
        })
        followedUsers.forEach((user) => {
            followedPostsDBs.push(db.collection('users').doc(user).collection('posts').where('timestamp', '<=', timestamp).get())
        })
        Promise.all(followedPostsDBs).then((postCollections) => {
            postCollections.forEach((postCollection) => {
                postCollection.docs.forEach((post) => {
                    if(post.exists){
                        let postData = post.data()
                        let postTimestamp = postData.timestamp.toDate()
                        if(postTimestamp <= expireTimestamp.toDate()){
                            post.ref.delete()
                        }
                        else{
                            postIDs.push({
                                id: post.id,
                                uid: postData.uid,
                                color: postData.color,
                                timestamp: postData.timestamp
                            })
                        }
                    }
                })
            })
            postIDs.slice(0, numPosts)
            res.status(200).json({posts: postIDs})
        })
    })
})