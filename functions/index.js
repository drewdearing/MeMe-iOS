const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp({
    credential: admin.credential.applicationDefault()
});

var db = admin.firestore();

const calculateVotes = (postID) => {
    let postDB = db.collection('post').doc(postID);
    let votesDB = postDB.collection('votes');
    return votesDB.get().then((votes) => {
        var upvotes = 0;
        var downvotes = 0;
        votes.docs.forEach((vote) => {
            let up = vote.get('up')
            if(up){
                upvotes++;
            }
            else{
                downvotes++;
            }
        });
        postDB.update({
            upvotes: upvotes,
            downvotes: downvotes
        });
    });
}

exports.onVoteCreate = functions.firestore
.document('post/{postID}/votes/{uid}')
.onCreate((snap, context) => {
    return calculateVotes(context.params.postID)
});

exports.onVoteUpdate = functions.firestore
.document('post/{postID}/votes/{uid}')
.onUpdate((change, context) => {
    return calculateVotes(context.params.postID)
});

exports.onVoteDelete = functions.firestore
.document('post/{postID}/votes/{uid}')
.onDelete((snap, context) => {
    return calculateVotes(context.params.postID)
});

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
    let postID = context.params.postID;
    let post = snap.data();
    let userDB = db.collection('users').doc(post.uid)
    return userDB.get().then((userDoc) => {
        if(userDoc.exists){
            var posts = userDoc.data().posts;
            posts = posts.filter(p => p !== postID);
            userDB.update({
                posts:posts
            });
        }
    });
});

exports.getUserFeed = functions.https.onRequest((req, res) => {
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
                                description: ''
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
                    res.status(200).json({
                        posts: postArray.slice(0, page*itemsPerPage)
                    });
                });
            });
        }
    });
});

exports.getDiscoverFeed = functions.https.onRequest((req, res) => {
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
                        description: ''
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
            res.status(200).json({
                posts: postArray.slice(0, page*itemsPerPage)
            });
        });
    });
});
