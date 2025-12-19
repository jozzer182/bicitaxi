// Initialize Firebase
if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
}

const auth = firebase.auth();
const db = firebase.firestore();

// DOM Elements
const loginSection = document.getElementById('login-section');
const profileSection = document.getElementById('profile-section');
const successSection = document.getElementById('success-section');
const googleLoginBtn = document.getElementById('google-login-btn');
const emailLoginBtn = document.getElementById('email-login-btn');
const emailInput = document.getElementById('email-input');
const passwordInput = document.getElementById('password-input');
const deleteAccountBtn = document.getElementById('delete-account-btn');
const logoutBtn = document.getElementById('logout-btn');
const loadingOverlay = document.getElementById('loading-overlay');
const userPhoto = document.getElementById('user-photo');
const userName = document.getElementById('user-name');
const userEmail = document.getElementById('user-email');

// Auth State Observer
auth.onAuthStateChanged((user) => {
    hideLoading();
    if (user) {
        showProfile(user);
    } else {
        showLogin();
    }
});

// Google Login Function
googleLoginBtn.addEventListener('click', () => {
    const provider = new firebase.auth.GoogleAuthProvider();
    auth.signInWithPopup(provider).catch((error) => {
        console.error("Login failed:", error);
        alert("Error al iniciar sesión: " + error.message);
    });
});

// Email Login Function
emailLoginBtn.addEventListener('click', () => {
    const email = emailInput.value;
    const password = passwordInput.value;

    if (!email || !password) {
        alert("Por favor ingresa correo y contraseña");
        return;
    }

    showLoading();
    auth.signInWithEmailAndPassword(email, password)
        .catch((error) => {
            hideLoading();
            console.error("Login failed:", error);
            let message = "Error al iniciar sesión: " + error.message;
            if (error.code === 'auth/wrong-password' || error.code === 'auth/user-not-found' || error.code === 'auth/invalid-credential') {
                message = "Correo o contraseña incorrectos.";
            } else if (error.code === 'auth/invalid-email') {
                message = "El formato del correo es inválido.";
            }
            alert(message);
        });
});

// Logout Function
logoutBtn.addEventListener('click', () => {
    auth.signOut();
});

// Delete Account Function
deleteAccountBtn.addEventListener('click', async () => {
    if (!confirm('¿Estás SEGURO de que deseas eliminar tu cuenta permanentemente? Esta acción NO se puede deshacer.')) {
        return;
    }

    // Double confirmation
    const email = auth.currentUser.email;
    const confirmation = prompt(`Para confirmar, escribe tu correo electrónico (${email}):`);

    if (confirmation !== email) {
        alert("El correo no coincide. Cancelando operación.");
        return;
    }

    showLoading();

    try {
        const user = auth.currentUser;

        // 1. Delete user data from Firestore (example - adjust paths as needed)
        // Note: For better security, handle data deletion via Cloud Functions triggers
        // Here we just delete the Auth account which is the critical part

        // 2. Delete the user
        await user.delete();

        showSuccess();
    } catch (error) {
        console.error("Delete failed:", error);
        hideLoading();

        if (error.code === 'auth/requires-recent-login') {
            alert("Por seguridad, debes haber iniciado sesión recientemente para eliminar tu cuenta. Por favor, cierra sesión e inicia nuevamente.");
            auth.signOut();
        } else {
            alert("Error al eliminar cuenta: " + error.message);
        }
    }
});

// UI Helper Functions
function showLogin() {
    loginSection.classList.remove('hidden');
    profileSection.classList.add('hidden');
    successSection.classList.add('hidden');
}

function showProfile(user) {
    loginSection.classList.add('hidden');
    profileSection.classList.remove('hidden');
    successSection.classList.add('hidden');

    userPhoto.src = user.photoURL || 'https://via.placeholder.com/150';
    userName.textContent = user.displayName || 'Usuario';
    userEmail.textContent = user.email;
}

function showSuccess() {
    loginSection.classList.add('hidden');
    profileSection.classList.add('hidden');
    successSection.classList.remove('hidden');
}

function showLoading() {
    loadingOverlay.classList.remove('hidden');
}

function hideLoading() {
    loadingOverlay.classList.add('hidden');
}
