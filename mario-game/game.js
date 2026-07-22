// 우리 아이 마리오 - 초간단 사이드 스크롤 플랫포머
// 얼굴 이미지 교체 방법: assets/child-face.png 파일을 정사각형 아이 사진으로 교체하면 됩니다.

const WORLD_WIDTH = 3200;
const WORLD_HEIGHT = 480;
const GROUND_Y = WORLD_HEIGHT - 32;

class BootScene extends Phaser.Scene {
  constructor() { super('Boot'); }

  preload() {
    this.load.image('face', 'assets/child-face.png');
  }

  create() {
    this.buildTextures();
    this.scene.start('Play');
  }

  buildTextures() {
    const g = this.add.graphics();

    // ---- 땅/플랫폼 블록 (32x32) ----
    g.clear();
    g.fillStyle(0x8b5a2b, 1);
    g.fillRect(0, 0, 32, 32);
    g.fillStyle(0x6b3f1d, 1);
    g.fillRect(0, 0, 32, 6);
    g.generateTexture('ground', 32, 32);

    g.clear();
    g.fillStyle(0xc77b3b, 1);
    g.fillRect(0, 0, 32, 16);
    g.fillStyle(0xa85f27, 1);
    g.fillRect(0, 0, 32, 4);
    g.generateTexture('platform', 32, 16);

    // ---- 코인 ----
    g.clear();
    g.fillStyle(0xffd700, 1);
    g.fillCircle(10, 10, 10);
    g.fillStyle(0xfff2a8, 1);
    g.fillCircle(10, 10, 5);
    g.generateTexture('coin', 20, 20);

    // ---- 굼바(적) ----
    g.clear();
    g.fillStyle(0x7a3b1e, 1);
    g.fillEllipse(16, 18, 30, 24);
    g.fillStyle(0x000000, 1);
    g.fillCircle(9, 14, 3);
    g.fillCircle(23, 14, 3);
    g.fillStyle(0x4a2410, 1);
    g.fillRect(2, 26, 12, 6);
    g.fillRect(18, 26, 12, 6);
    g.generateTexture('goomba', 32, 32);

    // ---- 깃발(골) ----
    g.clear();
    g.fillStyle(0xcccccc, 1);
    g.fillRect(6, 0, 4, 200);
    g.fillStyle(0x2ecc71, 1);
    g.fillTriangle(10, 10, 10, 40, 46, 25);
    g.generateTexture('flag', 46, 200);

    // ---- 플레이어 몸통 (얼굴 자리는 비워둠) ----
    const bw = 40, bh = 56;
    const faceCx = bw / 2;
    const faceCy = 22;
    const faceSize = 28;
    g.clear();
    // 모자 (얼굴 위쪽에만)
    g.fillStyle(0xd62828, 1);
    g.fillRect(bw / 2 - 17, 2, 34, 8);
    g.fillEllipse(bw / 2, 9, 36, 10);
    // 셔츠/오버올 (얼굴 아래쪽부터)
    g.fillStyle(0xd62828, 1);
    g.fillRect(6, 36, bw - 12, 10);
    g.fillStyle(0x2c5fb5, 1);
    g.fillRect(4, 40, bw - 8, 16);
    g.fillStyle(0xffe0b2, 1);
    g.fillRect(0, 40, 6, 12);
    g.fillRect(bw - 6, 40, 6, 12);
    // 신발
    g.fillStyle(0x3b2411, 1);
    g.fillRect(4, bh - 8, 14, 8);
    g.fillRect(bw - 18, bh - 8, 14, 8);
    g.generateTexture('playerBody', bw, bh);
    g.destroy();

    // ---- 몸통 + 아이 얼굴 합성 (캔버스 2D로 직접 그리기) ----
    const canvasTex = this.textures.createCanvas('player', bw, bh);
    const ctx = canvasTex.getContext();

    ctx.drawImage(this.textures.get('playerBody').getSourceImage(), 0, 0);

    ctx.save();
    ctx.beginPath();
    ctx.arc(faceCx, faceCy, faceSize / 2, 0, Math.PI * 2);
    ctx.closePath();
    ctx.clip();
    ctx.drawImage(
      this.textures.get('face').getSourceImage(),
      faceCx - faceSize / 2, faceCy - faceSize / 2, faceSize, faceSize
    );
    ctx.restore();

    canvasTex.refresh();
  }
}

class PlayScene extends Phaser.Scene {
  constructor() { super('Play'); }

  create() {
    this.physics.world.setBounds(0, 0, WORLD_WIDTH, WORLD_HEIGHT);
    this.cameras.main.setBounds(0, 0, WORLD_WIDTH, WORLD_HEIGHT);
    this.cameras.main.setBackgroundColor('#5c94fc');

    this.gameOver = false;
    this.won = false;
    this.score = 0;

    this.buildLevel();
    this.buildPlayer();
    this.buildUI();
    this.buildInput();

    this.physics.add.collider(this.player, this.groundGroup);
    this.physics.add.collider(this.player, this.platformGroup);
    this.physics.add.collider(this.goombas, this.groundGroup);
    this.physics.add.collider(this.goombas, this.platformGroup);

    this.physics.add.overlap(this.player, this.coins, this.collectCoin, null, this);
    this.physics.add.overlap(this.player, this.goombas, this.hitGoomba, null, this);
    this.physics.add.overlap(this.player, this.flag, this.reachFlag, null, this);

    this.cameras.main.startFollow(this.player, true, 0.12, 0.12);
    this.cameras.main.setDeadzone(120, 100);
  }

  buildLevel() {
    this.groundGroup = this.physics.add.staticGroup();
    for (let x = 0; x < WORLD_WIDTH; x += 32) {
      // 중간에 구멍(함정) 하나
      if (x > 900 && x < 964) continue;
      this.groundGroup.create(x + 16, GROUND_Y + 16, 'ground');
    }

    this.platformGroup = this.physics.add.staticGroup();
    const platforms = [
      [300, 360], [332, 360], [364, 360],
      [560, 300], [592, 300],
      [820, 340],
      [1100, 320], [1132, 320], [1164, 320],
      [1400, 280],
      [1700, 340], [1732, 340],
      [2000, 300], [2032, 300], [2064, 300],
      [2350, 260],
      [2650, 340], [2682, 340],
    ];
    platforms.forEach(([x, y]) => this.platformGroup.create(x, y, 'platform'));

    this.coins = this.physics.add.group({ allowGravity: false });
    const coinSpots = [
      [300, 320], [332, 320], [364, 320],
      [560, 260], [592, 260],
      [1100, 280], [1132, 280], [1164, 280],
      [1400, 240],
      [2000, 260], [2032, 260], [2064, 260],
      [2350, 220],
    ];
    coinSpots.forEach(([x, y]) => {
      const c = this.coins.create(x, y, 'coin');
      this.tweens.add({ targets: c, y: y - 6, duration: 500, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
    });

    this.goombas = this.physics.add.group();
    const goombaSpots = [700, 1250, 1850, 2200, 2500];
    goombaSpots.forEach((x) => {
      const gm = this.goombas.create(x, GROUND_Y - 20, 'goomba');
      gm.setVelocityX(-60);
      gm.setBounce(1, 0);
      gm.setCollideWorldBounds(true);
      gm.direction = -1;
    });

    this.flag = this.physics.add.staticGroup();
    this.flag.create(WORLD_WIDTH - 60, GROUND_Y - 100, 'flag');
  }

  buildPlayer() {
    this.player = this.physics.add.sprite(80, GROUND_Y - 100, 'player');
    this.player.setCollideWorldBounds(true);
    this.player.setDragX(900);
    this.player.setMaxVelocity(220, 700);
    this.player.body.setSize(28, 50).setOffset(6, 6);
  }

  buildUI() {
    this.scoreText = this.add.text(16, 14, '코인: 0', {
      fontFamily: 'sans-serif', fontSize: 20, color: '#ffffff', stroke: '#000000', strokeThickness: 4,
    }).setScrollFactor(0).setDepth(20);

    this.messageText = this.add.text(this.scale.width / 2, this.scale.height / 2, '', {
      fontFamily: 'sans-serif', fontSize: 36, color: '#ffffff', stroke: '#000000', strokeThickness: 6, align: 'center',
    }).setOrigin(0.5).setScrollFactor(0).setDepth(30).setVisible(false);
  }

  buildInput() {
    this.cursors = this.input.keyboard.createCursorKeys();
    this.touch = { left: false, right: false, jump: false };

    const bind = (id, key) => {
      const el = document.getElementById(id);
      const down = (e) => { e.preventDefault(); this.touch[key] = true; };
      const up = (e) => { e.preventDefault(); this.touch[key] = false; };
      el.addEventListener('touchstart', down, { passive: false });
      el.addEventListener('touchend', up, { passive: false });
      el.addEventListener('mousedown', down);
      el.addEventListener('mouseup', up);
      el.addEventListener('mouseleave', up);
    };
    bind('btn-left', 'left');
    bind('btn-right', 'right');
    bind('jump-btn', 'jump');
  }

  collectCoin(player, coin) {
    coin.destroy();
    this.score += 1;
    this.scoreText.setText('코인: ' + this.score);
  }

  hitGoomba(player, goomba) {
    if (this.gameOver || this.won) return;
    if (player.body.velocity.y > 0 && player.y < goomba.y - 6) {
      goomba.destroy();
      player.setVelocityY(-350);
    } else {
      this.endGame(false);
    }
  }

  reachFlag() {
    if (!this.gameOver && !this.won) this.endGame(true);
  }

  endGame(win) {
    this.won = win;
    this.gameOver = !win;
    this.player.setVelocity(0, win ? this.player.body.velocity.y : 0);
    this.physics.pause();
    this.messageText.setText(win ? '클리어! 🎉\n탭해서 다시 시작' : '게임 오버 😵\n탭해서 다시 시작');
    this.messageText.setVisible(true);
    this.input.once('pointerdown', () => this.scene.restart());
  }

  update() {
    if (this.gameOver || this.won) return;

    const player = this.player;
    const onFloor = player.body.blocked.down || player.body.touching.down;
    const left = this.cursors.left.isDown || this.touch.left;
    const right = this.cursors.right.isDown || this.touch.right;
    const jump = this.cursors.up.isDown || this.cursors.space?.isDown || this.touch.jump;

    if (left) {
      player.setVelocityX(-180);
      player.flipX = true;
    } else if (right) {
      player.setVelocityX(180);
      player.flipX = false;
    }

    if (jump && onFloor) {
      player.setVelocityY(-420);
    }

    this.goombas.children.iterate((gm) => {
      if (!gm || !gm.body) return;
      if (gm.body.blocked.left) gm.setVelocityX(60);
      if (gm.body.blocked.right) gm.setVelocityX(-60);
    });

    if (player.y > WORLD_HEIGHT + 100) {
      this.endGame(false);
    }
  }
}

const config = {
  type: Phaser.AUTO,
  parent: 'game-root',
  width: 480,
  height: WORLD_HEIGHT,
  backgroundColor: '#5c94fc',
  physics: {
    default: 'arcade',
    arcade: { gravity: { y: 1200 }, debug: false },
  },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  scene: [BootScene, PlayScene],
};

new Phaser.Game(config);
