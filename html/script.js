let isAdmin = false;
let config = {};
let playersData = [];

// Escuchar mensajes del cliente
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'toggleScoreboard':
            toggleScoreboard(data.show);
            break;
        case 'updateData':
            updateScoreboardData(data);
            break;
        case 'updatePlayers':
            updatePlayersData(data.players);
            break;
        case 'showPoliceConfirmation':
            showPoliceConfirmation(data);
            break;
    }
});

function toggleScoreboard(show) {
    const container = document.getElementById('scoreboard-container');
    if (show) {
        container.classList.add('show');
    } else {
        container.classList.remove('show');
    }
}

function updateScoreboardData(data) {
    isAdmin = data.isAdmin;
    config = data.config;

    // Actualizar títulos configurables
    updateTitles(data.config);

    // Actualizar contador de jugadores en línea
    const onlineElement = document.getElementById('online-number-mini');
    if (onlineElement) {
        onlineElement.textContent = data.playersOnline;
    }

    // Actualizar información del usuario
    updateUserProfile(data.playerData);

    // Actualizar trabajos
    updateJobsSection(data.jobCounts);

    // Actualizar robos
    updateRobberiesSection(data.robberyStatus);

    // Inicializar drag scrolling después de actualizar el contenido
    setTimeout(() => {
        initializeDragScrolling();
    }, 100);
}

function updateTitles(config) {
    // Actualizar título de la página
    const pageTitle = document.getElementById('page-title');
    if (pageTitle && config.ScoreboardTitle) {
        pageTitle.textContent = config.ScoreboardTitle;
    }

    // Actualizar nombre del servidor
    const serverName = document.getElementById('server-name');
    if (serverName && config.ServerName) {
        serverName.textContent = config.ServerName.toUpperCase();
    }

    // Actualizar título del scoreboard
    const scoreboardTitle = document.getElementById('scoreboard-title');
    if (scoreboardTitle && config.ScoreboardTitle) {
        scoreboardTitle.textContent = config.ScoreboardTitle.toUpperCase();
    }
}

function updateUserProfile(playerData) {
    if (!playerData) return;

    // Actualizar nombre del jugador
    const userNameElement = document.getElementById('user-name');
    if (userNameElement && playerData.name) {
        userNameElement.textContent = `Hello, ${playerData.name}`;
    }

    // Actualizar estado de admin
    const adminStatusElement = document.getElementById('user-admin-status');
    if (adminStatusElement) {
        adminStatusElement.textContent = isAdmin ? 'ADMIN' : 'USER';
        adminStatusElement.style.color = isAdmin ? '#10b981' : '#7dd3fc';
    }

    // Actualizar trabajo actual
    const userJobElement = document.getElementById('user-job');
    if (userJobElement && playerData.job) {
        // Buscar el label del trabajo en la configuración
        const jobConfig = config.Jobs.find(job => job.name === playerData.job);
        const jobLabel = jobConfig ? jobConfig.label : playerData.job;
        userJobElement.textContent = jobLabel;
    }

    // Actualizar avatar si hay URL de Steam
    const avatarImg = document.getElementById('user-avatar');
    const defaultAvatar = document.getElementById('default-avatar');

    if (playerData.steamAvatar && avatarImg && defaultAvatar) {
        avatarImg.src = playerData.steamAvatar;
        avatarImg.style.display = 'block';
        defaultAvatar.style.display = 'none';

        // Manejar error de carga de imagen
        avatarImg.onerror = function() {
            avatarImg.style.display = 'none';
            defaultAvatar.style.display = 'block';
        };
    }
}

function updateJobsSection(jobCounts) {
    const container = document.getElementById('jobs-container');
    container.innerHTML = '';

    config.Jobs.forEach(job => {
        const count = jobCounts[job.name] || 0;

        const jobDiv = document.createElement('div');

        // Determinar la clase CSS basada en el trabajo
        let jobClass = 'default';
        if (job.name === 'police') jobClass = 'police';
        else if (job.name === 'ambulance') jobClass = 'ambulance';
        else if (job.name === 'mechanic') jobClass = 'mechanic';
        else jobClass = 'default';

        jobDiv.className = `job-item ${jobClass}`;
        jobDiv.onclick = (e) => {
            // Solo permitir clic si el contenedor padre no está siendo arrastrado
            const container = document.getElementById('jobs-container');
            if (!container.classList.contains('dragging') && isAdmin) {
                e.stopPropagation();
                changeJob(job.name);
            }
        };

        jobDiv.innerHTML = `
            <div class="job-icon"><i class="${job.icon}"></i></div>
            <div class="job-label">${job.label}</div>
            <div class="job-count">${count}</div>
            ${isAdmin ? `<button class="admin-btn" onclick="event.stopPropagation(); changeJob('${job.name}')">+</button>` : ''}
        `;

        container.appendChild(jobDiv);
    });
}

function updateRobberiesSection(robberyStatus) {
    const container = document.getElementById('robberies-container');
    container.innerHTML = '';

    config.Robberies.forEach(robbery => {
        const status = robberyStatus[robbery.name] || {
            active: false,
            currentCount: 0,
            requiredCount: robbery.requiredCount,
            requiredJob: robbery.requiredJob,
            inProgress: false
        };

        const robberyDiv = document.createElement('div');
        let statusClass = 'inactive';
        let statusText = 'Disabled';

        if (status.inProgress) {
            statusClass = 'in-progress';
            statusText = 'En Progreso';
        } else if (status.active) {
            statusClass = 'active';
            statusText = 'Active';
        }

        robberyDiv.className = `robbery-item ${statusClass} ${robbery.name}`;

        // Agregar evento de clic solo si está activo
        if (status.active && !status.inProgress) {
            robberyDiv.onclick = () => {
                showRobberyModal(robbery);
            };
        }

        robberyDiv.innerHTML = `
            <div class="robbery-content">
                <div class="robbery-header">
                    <div class="robbery-icon"><i class="${robbery.icon}"></i></div>
                    <div class="robbery-label">${robbery.label}</div>
                </div>
                <div class="robbery-footer">
                    <div class="status-badge ${statusClass}">
                        ${statusText}
                    </div>
                    <div class="requirement-text">${status.currentCount}/${status.requiredCount} ${status.requiredJob}</div>
                </div>
            </div>
        `;

        container.appendChild(robberyDiv);
    });
}

function changeJob(jobName) {
    fetch(`https://${GetParentResourceName()}/changeJob`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            job: jobName
        })
    });
}

function closeScoreboard() {
    fetch(`https://${GetParentResourceName()}/closeScoreboard`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

// Funciones para el sistema de robos
function showRobberyModal(robbery) {
    const modal = document.getElementById('robbery-modal');
    const title = document.getElementById('modal-title');
    const message = document.getElementById('modal-message');
    const confirmBtn = document.getElementById('modal-confirm');
    const cancelBtn = document.getElementById('modal-cancel');

    title.textContent = robbery.label;
    message.textContent = '¿Te gustaría empezar el robo?';

    modal.classList.add('show');

    // Limpiar eventos anteriores
    confirmBtn.onclick = null;
    cancelBtn.onclick = null;

    confirmBtn.onclick = () => {
        hideRobberyModal();
        requestRobbery(robbery);
    };

    cancelBtn.onclick = () => {
        hideRobberyModal();
    };
}

function hideRobberyModal() {
    const modal = document.getElementById('robbery-modal');
    modal.classList.remove('show');
}

function requestRobbery(robbery) {
    fetch(`https://${GetParentResourceName()}/requestRobbery`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            robberyName: robbery.name,
            robberyLabel: robbery.label
        })
    });
}

// Función para mostrar modal de confirmación a la policía
function showPoliceConfirmation(data) {
    const modal = document.getElementById('robbery-modal');
    const title = document.getElementById('modal-title');
    const message = document.getElementById('modal-message');
    const confirmBtn = document.getElementById('modal-confirm');
    const cancelBtn = document.getElementById('modal-cancel');

    title.textContent = 'Petición de Robo';
    message.textContent = `${data.playerName} quiere empezar el robo: ${data.robberyLabel}. ¿Aceptar petición?`;

    confirmBtn.textContent = 'Aceptar';
    cancelBtn.textContent = 'Rechazar';

    modal.classList.add('show');

    // Limpiar eventos anteriores
    confirmBtn.onclick = null;
    cancelBtn.onclick = null;

    confirmBtn.onclick = () => {
        hideRobberyModal();
        respondToRobberyRequest(data.robberyName, true);
        confirmBtn.textContent = 'Sí';
        cancelBtn.textContent = 'No';
    };

    cancelBtn.onclick = () => {
        hideRobberyModal();
        respondToRobberyRequest(data.robberyName, false);
        confirmBtn.textContent = 'Sí';
        cancelBtn.textContent = 'No';
    };
}

function respondToRobberyRequest(robberyName, accepted) {
    fetch(`https://${GetParentResourceName()}/respondRobberyRequest`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            robberyName: robberyName,
            accepted: accepted
        })
    });
}

// Cerrar con ESC (se maneja en el DOMContentLoaded para evitar duplicados)

// Funcionalidad de arrastrar para scroll horizontal
function addDragScrolling(element) {
    let isDown = false;
    let startX;
    let scrollLeft;
    let hasMoved = false;

    element.addEventListener('mousedown', (e) => {
        // Solo activar si no se hace clic en un botón o elemento interactivo
        if (e.target.tagName === 'BUTTON' || e.target.closest('button')) {
            return;
        }

        isDown = true;
        hasMoved = false;
        element.classList.add('dragging');
        startX = e.pageX - element.offsetLeft;
        scrollLeft = element.scrollLeft;
        e.preventDefault();
    });

    element.addEventListener('mouseleave', () => {
        isDown = false;
        element.classList.remove('dragging');
    });

    element.addEventListener('mouseup', () => {
        isDown = false;
        element.classList.remove('dragging');

        // Si no se movió, permitir el clic
        if (!hasMoved) {
            // El clic se manejará normalmente
        }
    });

    element.addEventListener('mousemove', (e) => {
        if (!isDown) return;
        e.preventDefault();
        hasMoved = true;
        const x = e.pageX - element.offsetLeft;
        const walk = (x - startX) * 2;
        element.scrollLeft = scrollLeft - walk;
    });

    // Prevenir el comportamiento de arrastrar imágenes
    element.addEventListener('dragstart', (e) => {
        e.preventDefault();
    });
}

// Inicializar drag scrolling cuando se cargue el DOM
document.addEventListener('DOMContentLoaded', function() {
    const jobsContainer = document.getElementById('jobs-container');

    if (jobsContainer) {
        addDragScrolling(jobsContainer);
    }
});

// También inicializar cuando se actualicen los datos
function initializeDragScrolling() {
    const jobsContainer = document.getElementById('jobs-container');

    if (jobsContainer) {
        addDragScrolling(jobsContainer);
    }
}

// Funciones para las pestañas y jugadores
function updatePlayersData(players) {
    playersData = players;
    renderPlayersList();
}

function switchTab(tabName) {
    // Remover clase active de todos los botones y contenidos
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));

    // Agregar clase active al botón y contenido seleccionado
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    document.getElementById(`${tabName}-tab`).classList.add('active');

    // Si se cambia a la pestaña de jugadores, solicitar datos actualizados
    if (tabName === 'players') {
        fetch(`https://${GetParentResourceName()}/getPlayersData`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        });
    }
}

function renderPlayersList() {
    const playersList = document.getElementById('players-list');
    const searchInput = document.getElementById('player-search');
    const searchTerm = searchInput.value.toLowerCase();

    playersList.innerHTML = '';

    // Filtrar jugadores basado en la búsqueda
    const filteredPlayers = playersData.filter(player =>
        player.name.toLowerCase().includes(searchTerm)
    );

    filteredPlayers.forEach(player => {
        const playerItem = document.createElement('div');
        playerItem.className = 'player-item';

        // Determinar el ping y su clase
        let pingClass = 'ping-good';
        if (player.ping > 100) pingClass = 'ping-medium';
        if (player.ping > 200) pingClass = 'ping-bad';

        // Crear las barras de ping
        const pingBars = Array.from({length: 4}, (_, i) => {
            const shouldShow = player.ping <= 50 ? true :
                              player.ping <= 100 ? i < 3 :
                              player.ping <= 200 ? i < 2 : i < 1;
            return `<div class="ping-bar bar${i+1}" style="opacity: ${shouldShow ? 1 : 0.3}"></div>`;
        }).join('');

        // Crear tags del jugador
        let tags = '';
        if (player.isAdmin) {
            tags += '<span class="player-tag admin">Admin</span>';
        }
        if (player.job) {
            // Buscar el label del trabajo en la configuración
            const jobConfig = config.Jobs ? config.Jobs.find(job => job.name === player.job) : null;
            const jobLabel = jobConfig ? jobConfig.label : player.job;
            tags += `<span class="player-tag job">${jobLabel}</span>`;
        }

        playerItem.innerHTML = `
            <div class="player-avatar">
                ${player.steamAvatar ?
                    `<img src="${player.steamAvatar}" alt="${player.name}" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                     <i class="fas fa-user" style="display: none;"></i>` :
                    `<i class="fas fa-user"></i>`
                }
            </div>
            <div class="player-info">
                <div class="player-name">${player.name}</div>
                <div class="player-tags">${tags}</div>
            </div>
            <div class="player-ping">
                <div class="ping-bars ${pingClass}">
                    ${pingBars}
                </div>
                <span>${player.ping}</span>
            </div>
        `;

        playersList.appendChild(playerItem);
    });
}

// Event listeners para las pestañas y jugadores
document.addEventListener('DOMContentLoaded', function() {
    // Event listeners para las pestañas
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');
            switchTab(tabName);
        });
    });

    // Búsqueda de jugadores
    const searchInput = document.getElementById('player-search');
    if (searchInput) {
        searchInput.addEventListener('input', renderPlayersList);
    }

    // Click en el contador de usuarios online para ir a la pestaña de jugadores
    const onlineCounter = document.querySelector('.online-count-mini');
    if (onlineCounter) {
        onlineCounter.addEventListener('click', function() {
            switchTab('players');
        });
    }

    // Cerrar modal con ESC
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            const robberyModal = document.getElementById('robbery-modal');

            if (robberyModal.classList.contains('show')) {
                hideRobberyModal();
            } else {
                closeScoreboard();
            }
        }
    });
});
