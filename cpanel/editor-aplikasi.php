<?php
declare(strict_types=1);
require_once __DIR__.'/lib.php';
need_admin();
require_once __DIR__.'/app-designer-schema-2620.php';
header('X-Frame-Options: SAMEORIGIN');

$pages=cikoko_ui_pages_2620();
$homeKeys=cikoko_ui_home_keys_2620();
$page=(string)($_GET['page']??'Dashboard');
if(!isset($pages[$page]))$page='Dashboard';
$store=cikoko_ui_read_store_2620();
$notice='';$error='';
if(($_SERVER['REQUEST_METHOD']??'GET')==='POST'){
  csrf_check();
  $action=(string)($_POST['action']??'');
  $page=(string)($_POST['page']??'Dashboard');
  if(!isset($pages[$page]))$page='Dashboard';
  $draft=is_array($store['draft']??null)?$store['draft']:[];
  try {
    if(in_array($action,['save','publish'],true)){
      $raw=(string)($_POST['layout_json']??'');
      if(strlen($raw)>48000)throw new InvalidArgumentException('Konfigurasi halaman terlalu besar.');
      $decoded=json_decode($raw,true,64,JSON_THROW_ON_ERROR);
      $draft[$page]=cikoko_ui_normalize_page_2620($decoded,$page);
      $store['draft']=$draft;
    }
    if($action==='publish'){
      $published=[];
      foreach($draft as $slug=>$layout){
        if(!isset($pages[$slug]))continue;
        $published[$slug]=cikoko_ui_normalize_page_2620($layout,$slug);
      }
      $history=is_array($store['history']??null)?$store['history']:[];
      if(!empty($store['published'])){
        $history[]=[
          'revision'=>(int)($store['revision']??0),
          'published_at'=>(string)($store['published_at']??''),
          'pages'=>$store['published']
        ];
      }
      $store['history']=array_slice($history,-10);
      $store['published']=$published;
      $store['revision']=max(0,(int)($store['revision']??0))+1;
      $store['published_at']=gmdate('c');
    } elseif($action==='revert_draft'){
      if(isset($store['published'][$page]))
        $store['draft'][$page]=cikoko_ui_normalize_page_2620($store['published'][$page],$page);
      else unset($store['draft'][$page]);
    } elseif($action==='rollback'){
      $history=$store['history']??[];
      if(!is_array($history)||!$history)throw new InvalidArgumentException('Belum ada riwayat publikasi.');
      $previous=array_pop($history);
      $store['history']=$history;
      $store['published']=$previous['pages'];
      $store['draft']=$previous['pages'];
      $store['revision']=max(0,(int)($store['revision']??0))+1;
      $store['published_at']=gmdate('c');
    } elseif($action!=='save'){
      throw new InvalidArgumentException('Aksi tidak dikenal.');
    }
    if(!db_write('cikoko_app_designer_2620',$store))
      throw new RuntimeException('Gagal menulis penyimpanan data. Periksa izin folder data.');
    header('Location: '.url('editor-aplikasi.php?page='.rawurlencode($page).'&result='.rawurlencode($action)));
    exit;
  }catch(Throwable $e){
    $error=$e instanceof JsonException?'Format JSON desain tidak valid.':$e->getMessage();
  }
}
$store=cikoko_ui_read_store_2620();
$current=isset($store['draft'][$page])?$store['draft'][$page]:
  ($store['published'][$page]??cikoko_ui_default_page_2620($page));
try {$current=cikoko_ui_normalize_page_2620($current,$page);}
catch(Throwable $e){$current=cikoko_ui_default_page_2620($page);}
$drafted=isset($store['draft'][$page]);
$revision=(int)($store['revision']??0);
$publishedAt=(string)($store['published_at']??'');
$notice=match((string)($_GET['result']??'')){
 'save'=>'Draft halaman berhasil disimpan.',
 'publish'=>'Desain dipublikasikan. Aplikasi mengambil versi baru saat halaman dibuka/disinkronkan.',
 'revert_draft'=>'Draft dikembalikan ke desain publikasi.',
 'rollback'=>'Desain publikasi sebelumnya dipulihkan.',
 default=>''
};
$jsonFlags=JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_HEX_TAG|JSON_HEX_AMP|JSON_HEX_APOS|JSON_HEX_QUOT;
?><!DOCTYPE html>
<html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Editor Desain Aplikasi · Cikoko Smart</title>
<style>
:root{font:14px/1.45 system-ui,-apple-system,Segoe UI,Arial,sans-serif;color:#152849;background:#f1f5fc}
*{box-sizing:border-box}body{margin:0}button,input,select,textarea{font:inherit}button{cursor:pointer}
a{color:inherit}.bar{height:67px;background:#0b2b57;color:#fff;display:flex;align-items:center;justify-content:space-between;padding:0 22px;gap:12px}
.logo{font-size:18px;font-weight:800}.logo small{display:block;font-size:11px;font-weight:400;color:#c2d4f6}.buttons{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
button,.action{border:1px solid #d7e1f2;border-radius:10px;background:white;padding:10px 13px;color:#113868;font-weight:700}
.action{display:inline-block;text-decoration:none}.primary{background:#0b65d9;color:#fff;border-color:#0b65d9}.publish{background:#15804e;color:#fff;border-color:#15804e}
.layout{display:grid;grid-template-columns:230px minmax(300px,1fr) 310px;min-height:calc(100vh - 67px)}
.sidebar,.inspector{padding:18px;border-right:1px solid #dce5f1;background:#fff}.inspector{border-left:1px solid #dce5f1;border-right:0}
.title{font-size:12px;text-transform:uppercase;letter-spacing:.09em;color:#62748d;font-weight:800;margin:10px 0}
.sidebar select,.inspector input,.inspector textarea,.inspector select{width:100%;border:1px solid #d4deec;border-radius:9px;padding:10px;background:#fff;color:#153453}
.sidebar select{margin-bottom:20px}.helper{color:#697d99;font-size:12px}.list-choice{display:grid;gap:9px}.list-choice button{text-align:left;font-weight:600}
.stage{padding:20px;min-width:0}.head{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px;gap:12px;flex-wrap:wrap}
.head h1{margin:0;font-size:23px}.head p{color:#61748b;margin:3px 0}.notice,.error{padding:12px;border-radius:10px;margin:0 0 12px}.notice{background:#e4f6e9;color:#0b6940}.error{background:#fff0eb;color:#ad3d26}
.canvas{max-width:480px;margin:15px auto;background:#fff;border-radius:30px;border:9px solid #122443;min-height:640px;box-shadow:0 20px 50px #17305030;overflow:hidden}
.app-top{background:white;padding:18px 14px;border-bottom:1px solid #edf1f8;display:flex;justify-content:space-between;font-weight:900}
.app-body{background:#f7f9fd;min-height:580px;padding:13px;display:grid;gap:9px;align-content:start}
.app-item{position:relative;display:block;background:#fff;border:1px solid #dce5ef;border-radius:14px;padding:13px;min-height:50px;text-align:left;cursor:grab}
.app-item.selected{outline:2px solid #1476ed}.app-item.hidden{opacity:.38}.app-item .drag{color:#9bb0c9;float:right}
.app-item h3{margin:0 0 4px;font-size:14px}.app-item p{margin:0;color:#67788e;font-size:12px;white-space:pre-wrap}
.app-item .example{font-size:20px;color:#148055;font-weight:900;margin-top:9px}
.app-item.is-banner{background:linear-gradient(125deg,#d5eaff,#f3f9ff);min-height:96px}
.app-item.is-spacer{border-style:dashed;min-height:20px}.pill{display:inline-block;font-size:10px;border-radius:6px;background:#eaf2fd;padding:3px 6px;color:#21569a;font-weight:700}
.field{margin:12px 0}.field label{display:block;font-weight:700;font-size:12px;margin-bottom:5px}.field input[type=color]{height:41px;padding:3px}
.inline{display:flex;align-items:center;gap:8px}.inline input{width:auto!important}.muted{color:#6b7d94}.small{font-size:11px}.divider{height:1px;background:#e5ebf3;margin:18px 0}
.section-label{font-weight:900;font-size:12px;color:#506784;margin:11px 0 2px}.actions{text-align:right;display:flex;flex-direction:column;gap:7px}
.toast{font-size:12px;color:#087441}.jsonhelp{padding:12px;background:#eef5ff;border-radius:12px;font-size:12px}
@media(max-width:1150px){.layout{grid-template-columns:185px minmax(260px,1fr) 270px}.sidebar,.inspector{padding:11px}}
@media(max-width:850px){.layout{grid-template-columns:1fr}.sidebar,.inspector{border:0;border-bottom:1px solid #dce5ef}.list-choice{grid-template-columns:repeat(2,1fr)}.stage{padding:12px}.canvas{max-width:480px}.bar{height:auto;min-height:67px;padding:10px}}
</style><link rel="stylesheet" href="<?=esc(url('assets/editor-mockup-2620.css'))?>"></head><body>
<header class="bar">
  <div class="logo"><span class="brand-mark" aria-hidden="true">✦</span><span>Cikoko Smart<small>Kelurahan Cikoko · Editor Desain Aplikasi 2620</small></span></div>
  <div class="buttons"><a class="action" href="/admin">← Dashboard Admin</a>
    <button form="saveForm" type="button" data-submit="save">▣ Simpan Draft</button>
    <button form="saveForm" type="button" class="publish" data-submit="publish">✓ Publikasikan</button>
  </div>
</header>
<div class="layout">
<aside class="sidebar">
  <div class="side-account"><span class="side-avatar" aria-hidden="true">♙</span><span><strong>Administrator</strong><small>Super Admin · Kelurahan Cikoko</small></span></div>
  <div class="title">Menu Administrator</div>
  <nav class="side-links" aria-label="Menu editor Cikoko">
    <a href="/admin"><span class="side-icon">⌂</span> Dashboard</a>
    <a href="?page=Dashboard" class="<?=$page==='Dashboard'?'active':''?>"><span class="side-icon">▦</span> Editor Beranda</a>
    <a href="?page=Bank%20Sampah%20Cikoko" class="<?=$page==='Bank Sampah Cikoko'?'active':''?>"><span class="side-icon">♻</span> Bank Sampah</a>
    <a href="?page=Layanan%20Online" class="<?=$page==='Layanan Online'?'active':''?>"><span class="side-icon">▤</span> Layanan Masyarakat</a>
    <a href="?page=Berita%20%26%20Kegiatan" class="<?=$page==='Berita & Kegiatan'?'active':''?>"><span class="side-icon">▧</span> Berita Terbaru</a>
    <a href="?page=Inovasi" class="<?=$page==='Inovasi'?'active':''?>"><span class="side-icon">✧</span> Inovasi</a>
    <a href="?page=Profil"><span class="side-icon">♙</span> Profil Pengguna</a>
    <a href="?page=Kinerja%20PPPK"><span class="side-icon">▥</span> Kinerja PPPK</a>
    <a href="?page=Absensi%20dan%20Kinerja%20PJLP"><span class="side-icon">◷</span> Absensi PJLP</a>
    <a href="?page=Laporan%20Jumantik"><span class="side-icon">▤</span> Jumantik</a>
    <a href="?page=Percakapan%20Chat"><span class="side-icon">☏</span> Chat dan Notifikasi</a>
  </nav>
  <div class="title">Pengaturan Tampilan</div>
  <nav class="side-links"><a class="active" href="?page=<?=rawurlencode($page)?>"><span class="side-icon">✥</span> Desain Aplikasi</a></nav>
  <div class="tip">✧ &nbsp; Desain mengikuti layar Android melalui API. Fungsi formulir, hak akses, saldo, QR, dan database tidak dapat diubah melalui editor.</div>
</aside>
<main class="stage">
  <div class="head"><div><h1>Editor Desain Aplikasi</h1><p>Ubah susunan halaman, teks, warna dan komponen. Lihat hasilnya di pratinjau Android.</p></div><span class="pill">● Mode Draft · Belum dipublikasikan</span></div>
  <?php if($notice):?><div class="notice"><?=esc($notice)?></div><?php endif;?>
  <?php if($error):?><div class="error"><?=esc($error)?></div><?php endif;?>
  <div class="studio-toolbar"><div class="tabs"><span class="tab selected">📱 Tampilan Android</span><span class="tab">↔ Grid responsif</span></div><span class="hint">Geser komponen atau gunakan tombol ↑ ↓ pada daftar susunan</span></div>
  <div class="studio">
    <section class="studio-panel" aria-label="Komponen dan pilihan halaman">
      <h2>Pustaka Komponen <small>Tambahkan elemen ke halaman Anda</small></h2>
      <div class="title">Halaman yang diedit</div>
      <select id="pageSelect" aria-label="Pilih halaman"><?php foreach($pages as $id=>$label):?><option value="<?=esc($id)?>" <?=$id===$page?'selected':''?>><?=esc($label)?></option><?php endforeach;?></select>
      <div class="title">Tambah Komponen</div>
      <div class="list-choice">
        <button type="button" data-add="heading"><span class="palette-icon">T</span> Judul / Heading</button>
        <button type="button" data-add="text"><span class="palette-icon">☷</span> Teks / Keterangan</button>
        <button type="button" data-add="card"><span class="palette-icon">▣</span> Kartu Informasi</button>
        <button type="button" data-add="spacer"><span class="palette-icon">↕</span> Jarak / Spacer</button>
      </div>
      <p class="helper">Klik komponen di pratinjau untuk mengubah detailnya pada panel kanan. Komponen native menggunakan data API sebenarnya di aplikasi.</p>
    </section>
    <section class="studio-panel" aria-label="Urutan komponen">
      <h2>Susunan Halaman <small>Urutkan komponen di halaman aktif</small></h2>
      <div class="layer-list" id="layerList"></div>
    </section>
    <section class="phone-panel" aria-label="Pratinjau Android">
      <h2>Pratinjau Android <span class="pill">Live preview</span></h2>
      <div class="canvas" id="phone" aria-label="Pratinjau desain aplikasi">
        <div class="phone-status"><span>9:50</span><span>▰▰ ▣ ▰ 80%</span></div>
        <div class="app-top">
          <div class="app-brand"><span style="font-size:16px" aria-hidden="true">☰</span><span class="app-brand-logo">✦</span><span class="app-brand-name"><strong>Cikoko Smart</strong><small>Kelurahan Cikoko · PJLP</small></span></div>
          <span class="phone-actions" aria-hidden="true">♧ &nbsp; ◉</span>
        </div>
        <div id="appBody" class="app-body" aria-live="polite"></div>
        <div class="phone-bottom" aria-label="Simulasi navigasi bawah">
          <span><b>▦</b>Layanan</span><span><b>✦</b>Inovasi</span><span class="on"><b>⌂</b>Beranda</span><span><b>▤</b>Laporan</span><span><b>♙</b>Profil</span>
        </div>
      </div>
      <p class="helper" style="text-align:center;max-width:330px">Angka dan konten pada pratinjau hanya contoh, bukan data akun. Hasil sebenarnya diambil melalui API.</p>
    </section>
  </div>
  <div class="editor-info">
    <div><strong>Revisi terbit: <?=esc($revision)?></strong><small>Terakhir dipublikasikan: <?=esc($publishedAt?:'Belum ada publikasi')?></small><small><?=$drafted?'Halaman ini mempunyai draft tersimpan.':'Halaman belum tersimpan sebagai draft.'?></small></div>
    <form class="action-row" method="post" id="rollbackForm"><input type="hidden" name="csrf" value="<?=esc(csrf())?>"><input type="hidden" name="page" value="<?=esc($page)?>">
      <button type="submit" name="action" value="revert_draft" onclick="return confirm('Kembalikan draft halaman ke publikasi?')">↶ Pulihkan Draft</button>
      <button type="submit" name="action" value="rollback" onclick="return confirm('Publikasikan kembali versi sebelumnya untuk semua halaman?')">↺ Rollback Publikasi</button>
    </form>
  </div>
</main>
<aside class="inspector">
 <div class="title">Pengaturan Halaman</div>
 <div class="field"><label for="pageTitle">Judul tambahan</label><input id="pageTitle" maxlength="90" placeholder="Opsional"></div>
 <div class="field"><label for="pageDescription">Keterangan halaman</label><textarea id="pageDescription" rows="3" maxlength="260"></textarea></div>
 <div class="field"><label for="accent">Warna aksen</label><input type="color" id="accent"></div>
 <div class="divider"></div>
 <div class="title">Pengaturan Komponen</div>
 <p id="emptyInspector" class="helper">Klik salah satu komponen pada pratinjau.</p>
 <div id="blockInspector" hidden>
  <div class="field"><label id="itemTitleLabel" for="itemTitle">Judul komponen</label><input id="itemTitle" maxlength="95"></div>
  <div class="field" id="itemBodyWrap"><label for="itemBody">Detail / Keterangan</label><textarea id="itemBody" rows="4" maxlength="750"></textarea></div>
  <div class="field inline"><input id="itemVisible" type="checkbox"><label for="itemVisible">Tampilkan</label></div>
  <div class="field" id="itemSizeWrap"><label for="itemSize">Ukuran</label><select id="itemSize"><option value="normal">Normal</option><option value="wide">Lebar</option></select></div>
  <div class="field" id="itemHeightWrap"><label for="itemHeight">Jarak (px preview)</label><input type="number" min="8" max="100" id="itemHeight"></div>
  <button type="button" id="removeBlock">Hapus Komponen Tambahan</button>
 </div>
 <div class="divider"></div>
 <div class="status-note"><strong>✓ Tampilan aman & responsif</strong>Desain dikirim melalui API. Kode Flutter, modul layanan, hak akses pegawai dan database tetap terlindungi.</div>
<div class="editor-features"><div class="title">Bisa diatur dari website</div>
<div class="feature"><span class="check">✓</span> Urutan komponen Beranda</div>
<div class="feature"><span class="check">✓</span> Teks dan kartu tambahan</div>
<div class="feature"><span class="check">✓</span> Warna aksen halaman</div>
<div class="feature"><span class="check">✓</span> Tampilkan / sembunyikan komponen yang diizinkan</div>
<div class="feature"><span class="check">✓</span> Draft, publikasi dan rollback</div>
<div class="feature"><span>◷</span> Upload media dan editor bebas-piksel: tahap berikutnya</div>
</div>
 <div class="jsonhelp"><strong>Keamanan tetap dijaga</strong><p>Editor hanya mengatur presentasi. Form, validasi, QR, tanda tangan, role, data pribadi dan persetujuan tetap diatur aplikasi/API asli.</p></div>
</aside>
</div>
<form method="post" id="saveForm"><input type="hidden" name="csrf" value="<?=esc(csrf())?>">
<input type="hidden" name="page" value="<?=esc($page)?>">
<input type="hidden" name="action" id="saveAction" value="save">
<input type="hidden" name="layout_json" id="layoutJson"></form>
<script type="application/json" id="layoutInitial"><?=json_encode($current,$jsonFlags)?></script>
<script type="application/json" id="homeLabels"><?=json_encode($homeKeys,$jsonFlags)?></script>
<script>
'use strict';
const clone=v=>JSON.parse(JSON.stringify(v));
let model=clone(JSON.parse(document.getElementById('layoutInitial').textContent));
const labels=JSON.parse(document.getElementById('homeLabels').textContent);
const selectedPage=<?=json_encode($page,$jsonFlags)?>;
const body=document.getElementById('appBody');
const $=id=>document.getElementById(id);
let selected=null,dirty=false;
const selectionKey=(type,id)=>type+':'+id;
function persist(){dirty=true}
function render(){
  body.replaceChildren();
  if(model.title){const node=document.createElement('h2');node.textContent=model.title;node.style.margin='0';node.style.color=model.accent;body.append(node);}
  if(model.description){const node=document.createElement('p');node.textContent=model.description;node.style.whiteSpace='pre-wrap';node.style.color='#61748b';body.append(node);}
  const ordered=[];
  if(selectedPage==='Dashboard')for(const section of model.sections||[]){
    ordered.push({kind:'section',id:section.key,visible:section.visible, title:labels[section.key]||section.key});
  }
  for(const block of model.blocks||[])ordered.push({kind:'block',...block});
  const hint=document.createElement('div');hint.className='section-label';hint.textContent=selectedPage==='Dashboard'?'Seret untuk mengatur urutan Beranda':'Komponen tambahan pada halaman ini';body.append(hint);
  for(const item of ordered){
    const div=document.createElement('div');
    const id=selectionKey(item.kind,item.id);
    div.className='app-item'+(selected===id?' selected':'')+(item.visible?'':' hidden')+((item.id==='hero')?' is-banner':'')+(item.type==='spacer'?' is-spacer':'');
    div.dataset.kind=item.kind;div.dataset.id=item.id;div.draggable=true;div.tabIndex=0;div.setAttribute('role','button');
    const grip=document.createElement('span');grip.textContent='⠿';grip.className='drag';div.append(grip);
    const h=document.createElement('h3');h.textContent=item.title||('Komponen '+item.type);div.append(h);
    if(item.kind==='block'){
      if(item.body){const p=document.createElement('p');p.textContent=item.body;div.append(p);}
      if(item.type==='spacer'){h.textContent='Jarak / Spacer';div.style.height=(item.height||16)+'px';}
    }else if(item.id==='bank_annual'){
      const ex=document.createElement('div');ex.className='example';ex.textContent='2.930,78 Kg  |  Rp 7.473.660';div.append(ex);
      const p=document.createElement('p');p.textContent='Data ilustrasi, bukan data server';div.append(p);
    }else if(item.id==='letters'){
      const p=document.createElement('p');p.textContent='Surat Masuk  •  Diproses  •  Selesai';div.append(p);
    }else if(item.id==='hero'){
      const p=document.createElement('p');p.textContent='Kelurahan Cikoko · Kecamatan Pancoran';div.append(p);
    }
    div.addEventListener('click',()=>choose(item.kind,item.id));
    div.addEventListener('keydown',e=>{if(e.key==='Enter')choose(item.kind,item.id)});
    div.addEventListener('dragstart',e=>{e.dataTransfer.setData('text/plain',id);e.dataTransfer.effectAllowed='move'});
    div.addEventListener('dragover',e=>e.preventDefault());
    div.addEventListener('drop',e=>{
      e.preventDefault();
      const [sourceKind,sourceId]=(e.dataTransfer.getData('text/plain')||'').split(':');
      if(sourceKind!==item.kind||sourceId===item.id)return;
      const list=sourceKind==='section'?model.sections:model.blocks;
      const from=list.findIndex(x=>(sourceKind==='section'?x.key:x.id)===sourceId);
      const to=list.findIndex(x=>(sourceKind==='section'?x.key:x.id)===item.id);
      if(from<0||to<0)return;
      list.splice(to,0,list.splice(from,1)[0]);
      persist();render();
    });
    body.append(div);
  }
}
function choose(kind,id){
  selected=selectionKey(kind,id);
  const item=kind==='section'?model.sections.find(v=>v.key===id):model.blocks.find(v=>v.id===id);
  $('emptyInspector').hidden=true;$('blockInspector').hidden=false;
  $('itemTitle').disabled=kind==='section';
  $('itemTitle').value=kind==='section'?labels[id]||id:item.title||'';
  $('itemTitleLabel').textContent=kind==='section'?'Nama bawaan (tetap)':'Judul komponen';
  $('itemBodyWrap').hidden=kind==='section';
  $('itemSizeWrap').hidden=kind==='section';
  $('itemHeightWrap').hidden=kind!=='block'||item.type!=='spacer';
  $('itemVisible').checked=item.visible!==false;
  $('itemVisible').disabled=kind==='section'&&id==='letters';
  $('itemBody').value=item.body||'';$('itemSize').value=item.size||'normal';
  $('itemHeight').value=item.height||16;
  $('removeBlock').hidden=kind==='section';
  render();
}
function editSelected(change){
 if(!selected)return;
 const [kind,id]=selected.split(':');
 const item=kind==='section'?model.sections.find(v=>v.key===id):model.blocks.find(v=>v.id===id);
 if(!item)return;change(item);persist();render();
}
$('pageTitle').value=model.title||'';$('pageDescription').value=model.description||'';
$('accent').value=model.accent||'#0967E7';
$('pageTitle').oninput=e=>{model.title=e.target.value;persist();render()};
$('pageDescription').oninput=e=>{model.description=e.target.value;persist();render()};
$('accent').oninput=e=>{model.accent=e.target.value;persist();render()};
$('itemTitle').oninput=e=>editSelected(x=>x.title=e.target.value);
$('itemBody').oninput=e=>editSelected(x=>x.body=e.target.value);
$('itemVisible').onchange=e=>editSelected(x=>x.visible=e.target.checked);
$('itemSize').onchange=e=>editSelected(x=>x.size=e.target.value);
$('itemHeight').oninput=e=>editSelected(x=>x.height=Math.max(8,Math.min(100,Number(e.target.value)||16)));
$('removeBlock').onclick=()=>{
 const [kind,id]=(selected||'').split(':');if(kind!=='block')return;
 model.blocks=model.blocks.filter(x=>x.id!==id);selected=null;
 $('blockInspector').hidden=true;$('emptyInspector').hidden=false;
 persist();render();
};
document.querySelectorAll('[data-add]').forEach(btn=>btn.onclick=()=>{
 if(model.blocks.length>=30){alert('Maksimal 30 komponen tambahan.');return;}
 const type=btn.dataset.add;
 const id='x'+Date.now().toString(36)+Math.random().toString(36).slice(2,8);
 const component={id,type,title:type==='heading'?'Judul Baru':type==='card'?'Kartu Baru':'',body:type==='text'?'Teks tambahan...':'',visible:true,size:'normal',height:16};
 model.blocks.push(component);persist();choose('block',id);
});
document.querySelectorAll('[data-submit]').forEach(btn=>btn.onclick=()=>{
 $('layoutJson').value=JSON.stringify(model);$('saveAction').value=btn.dataset.submit;
 if(btn.dataset.submit==='publish'&&!confirm('Terbitkan desain? Perubahan akan terlihat di aplikasi yang mendukung layout 2620.'))return;
 dirty=false;
 $('saveForm').submit();
});
$('pageSelect').onchange=e=>{
 if(dirty&&!confirm('Perubahan halaman belum disimpan. Pindah tanpa menyimpan?')){e.target.value=selectedPage;return;}
 location.href='?page='+encodeURIComponent(e.target.value);
};
window.addEventListener('beforeunload',e=>{if(dirty){e.preventDefault();e.returnValue='';}});
$('saveForm').addEventListener('submit',()=>{dirty=false});
render();
</script>
</body></html>