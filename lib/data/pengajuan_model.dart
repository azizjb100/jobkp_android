// File: lib/models/pengajuan_models.dart

import 'package:flutter/material.dart'; // Diperlukan untuk TextEditingController

class PengajuanListItem {
  final String nomor;
  final String detail;

  PengajuanListItem({required this.nomor, required this.detail});

  factory PengajuanListItem.fromJson(Map<String, dynamic> json) {
    return PengajuanListItem(
      nomor: json['Nomor'] ?? '',
      detail: json['Detail'] ?? '',
    );
  }
}

class PengajuanHeader {
  final String sppNomor;
  final DateTime sppTanggal;
  final String sppJob;
  final String sppKet;
  final String sppStatus;

  PengajuanHeader({
    required this.sppNomor,
    required this.sppTanggal,
    required this.sppJob,
    required this.sppKet,
    required this.sppStatus,
  });

  factory PengajuanHeader.fromJson(Map<String, dynamic> json) {
    return PengajuanHeader(
      sppNomor: json['spp_nomor'] ?? '',
      // Mengonversi string tanggal dari server menjadi objek DateTime
      sppTanggal:
          DateTime.tryParse(json['spp_tanggal'] ?? '') ?? DateTime.now(),
      sppJob: json['spp_job'] ?? '',
      sppKet: json['spp_ket'] ?? '',
      sppStatus: json['spp_status'] ?? 'BELUM',
    );
  }
}

/// Model untuk data Detail (dari tabel tsparepart_pengajuan_dtl).
/// Digunakan saat memuat data untuk mode edit.
class PengajuanDetail {
  final String kode;
  final String nama;
  final String satuan;
  final num qty;

  PengajuanDetail({
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.qty,
  });

  factory PengajuanDetail.fromJson(Map<String, dynamic> json) {
    return PengajuanDetail(
      kode: json['sppd_kode'] ?? '',
      nama: json['sp_nama'] ?? '',
      satuan: json['sp_satuan'] ?? '',
      qty: num.tryParse(json['sppd_qty'].toString()) ?? 0,
    );
  }
}

/// Model "Container" untuk menampung respons lengkap dari API (`getPengajuanById`).
class PengajuanData {
  final PengajuanHeader header;
  final List<PengajuanDetail> details;

  PengajuanData({required this.header, required this.details});

  factory PengajuanData.fromJson(Map<String, dynamic> json) {
    var detailList = json['details'] as List? ?? [];
    List<PengajuanDetail> details =
        detailList.map((d) => PengajuanDetail.fromJson(d)).toList();

    return PengajuanData(
      header: PengajuanHeader.fromJson(json['header'] ?? {}),
      details: details,
    );
  }
}

/// Model untuk Grid 1 (Read-only, kebutuhan dari Job).
/// Sesuai hasil dari `getJobDetailsForPengajuan`.
class JobKebutuhanDetail {
  final String nama;
  final String satuan;
  final num qty;
  JobKebutuhanDetail(
      {required this.nama, required this.satuan, required this.qty});

  factory JobKebutuhanDetail.fromJson(Map<String, dynamic> json) {
    return JobKebutuhanDetail(
      nama: json['jbd_nama'] ?? '',
      satuan: json['jbd_satuan'] ?? '',
      qty: num.tryParse(json['jbd_qty'].toString()) ?? 0,
    );
  }
}

/// Model untuk Grid 2 (Editable UI).
/// Ini adalah model khusus untuk UI, karena mengandung TextEditingController.
class PengajuanDetailItemUI {
  final String kode;
  final String nama;
  final String satuan;
  final TextEditingController qtyController;

  PengajuanDetailItemUI({
    required this.kode,
    required this.nama,
    required this.satuan,
    required this.qtyController,
  });
}

//==============================================================================
// Model untuk Dialog Pencarian (Lookup)
//==============================================================================

/// Model untuk item di dialog pencarian "Nomor Job".
/// Sesuai hasil dari `getAvailableJobs`.
class JobLookupItem {
  final String nomor;
  final String detail;
  JobLookupItem({required this.nomor, required this.detail});
  factory JobLookupItem.fromJson(Map<String, dynamic> json) {
    return JobLookupItem(
      nomor: json['Nomor'] ?? '',
      detail: json['Detail'] ?? '',
    );
  }
}

/// Model untuk item di dialog pencarian "Sparepart".
/// Sesuai hasil dari `getAvailableSpareparts`.
class SparepartLookupItem {
  final String kode;
  final String nama;
  final String satuan;
  final num stok;
  SparepartLookupItem(
      {required this.kode,
      required this.nama,
      required this.satuan,
      required this.stok});
  factory SparepartLookupItem.fromJson(Map<String, dynamic> json) {
    return SparepartLookupItem(
      kode: json['sp_kode'] ?? '',
      nama: json['sp_nama'] ?? '',
      satuan: json['sp_satuan'] ?? '',
      stok: num.tryParse(json['stok'].toString()) ?? 0,
    );
  }
}
